import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_validate/angel_validate.dart';
import 'package:blood_money/models.dart';
import 'package:intl/intl.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:isolate/load_balancer.dart';
import 'package:isolate/runner.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

final Uri recipsUrl = Uri.parse(
    'https://www.opensecrets.org/outsidespending/recips.php?cycle=2010&cmte=National%20Rifle%20Assn');

final Uri wikipediaIndex = Uri.parse('https://en.wikipedia.org/w/index.php');

final RegExp commaOrSpace = new RegExp(r'[, ]');

final RegExp moneyValid = new RegExp(r'[0-9,.]+');

final RegExp assumedOffice = new RegExp(r'[Aa]ssumed office');

final RegExp email = new RegExp(
    r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$");

final RegExp phoneNumber = new RegExp(r'\([0-9]+\)\s*[0-9]+\s*-[0-9]+');

var dateFormat = new DateFormat('MMMM d, yyy');

final DateTime now = new DateTime.now();

main() async {
  var client = new http.Client();
  var cycles = await getCycles(client);
  var pool = await LoadBalancer.create(
      Platform.numberOfProcessors, IsolateRunner.spawn);

  var scrapeTasks = cycles.map((cycle) {
    return pool.run(fetchFromCycle, cycle);
  });

  var polticians = await Future
      .wait(scrapeTasks)
      .then<List<Politician>>((list) => list.reduce((a, b) => a..addAll(b)));

  var uniquePoliticians = <Politician>[];

  for (var p in polticians) {
    var existing = uniquePoliticians.firstWhere((pp) => pp.name == p.name,
        orElse: () => null);

    if (existing == null)
      uniquePoliticians.add(p);
    else {
      existing
        ..website ??= p.website
        ..position ??= p.position
        ..imageUrl ??= p.imageUrl
        ..state ??= p.state
        ..email ??= p.email
        ..phone ??= p.phone
        ..party ??= p.party
        ..moneyFromNra += p.moneyFromNra;
    }
  }

  var dbFile = new File('db/politicians_db.json');
  await dbFile.create(recursive: true);

  var json = new JsonEncoder.withIndent('  ');
  await dbFile.writeAsString(json.convert(polticians));

  client.close();
}

/// Find all election cycles
///
/// i.e. `2010`, `2014`, etc.
Future<List<int>> getCycles(http.BaseClient client) async {
  var response = await client.get(recipsUrl);
  var doc = html.parse(response.body);
  var $select = doc.querySelector('select[name="GoToPage"]');
  var $options = $select.querySelectorAll('option');

  return $options.map(($option) {
    return int.parse($option.text);
  }).toList();
}

Future<List<Politician>> fetchFromCycle(int cycle) async {
  var client = new http.Client();

  try {
    var url = recipsUrl.replace(
      queryParameters: new Map.from(recipsUrl.queryParameters)
        ..['cycle'] = cycle.toString(),
    );
    var response = await client.get(url);
    var doc = html.parse(response.body);
    var $table = doc.querySelector('table');
    var $trs = $table.querySelector('tbody').querySelectorAll('tr');
    print('Cycle $cycle: ${$trs.length} Donation Record(s)');

    return await Future.wait($trs.map(($tr) async {
      var $tds = $tr.querySelectorAll('td');

      // Don't waste time parsing losers
      if ($tds[7].text.contains('Los')) return null;

      // Parse name, etc.
      var names = $tds[0]
          .text
          .split(commaOrSpace)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      var now = new DateTime.now();

      var p = new Politician(
        name: '${names[1]} ${names[0]}'.trim(),
        party: $tds[1].text == 'D' ? 'Democrat' : 'Republican',
        state: $tds[2].text,
        position: guessPosition($tds[3].text.trim()),
        createdAt: now,
        updatedAt: now,
      );

      if (p.state.isEmpty) p.state = 'USA';

      // Get rid of "three-name" situations
      if (names.length == 3) {
        p.name = '${names[1]} ${names[0]}'.trim();
        //print('$names - ${names.length}');
      }

      // Special case for Bob Latta
      if (p.name == 'Robert Latta') p.name = 'Bob Latta';

      // Guess website
      if (p.position == 'Senator')
        p.website = 'https://${names[0].toLowerCase()}.senate.gov';
      else if (p.position == 'Representative')
        p.website = 'https://${names[0].toLowerCase()}.house.gov';

      var moneyMatch = moneyValid.firstMatch($tds[5].text);

      if (moneyMatch == null) return null;

      var moneyForString =
          p.moneyFromNra = num.parse(moneyMatch[0].replaceAll(',', ''));

      // Don't document anyone who didn't receive donations.
      if (moneyForString <= 0) return null;

      // Scrape Wikipedia for info...
      p = await scrapeWikipedia(p, client);
      return p;
    })).then((it) => it.where((p) => p != null).toList());
  } finally {
    client.close();
  }
}

String guessPosition(String s) {
  switch (s) {
    case 'Senate':
      return 'Senator';
    case 'House':
      return 'Representative';
    default:
      return s;
  }
}

Future<Politician> scrapeWikipedia(Politician p, http.BaseClient client) async {
  // search=donald+trump&title=Special%3ASearch&go=Go
  var url = wikipediaIndex.replace(queryParameters: {
    'search': p.name,
    'title': 'Special Search',
    'go': 'Go',
  });
  http.Response response;

  try {
    response = await client.get(url);

    var doc = html.parse(response.body);

    // Check if incumbent
    if (doc.querySelector('a[title="Incumbent"]') == null) {
      print('Not incumbent: ${p.name}');
      return null;
    }

    p.imageUrl = 'https:' +
        doc
            .querySelectorAll('a.image')[0]
            .querySelector('img')
            .attributes['src'];

    p = await scrapeReelectionFromVcard(p, doc);

    if (p != null) p = await scrapeEmailAndPhoneFromWebsite(p, client);

    return p;
  } catch (e, st) {
    print('Error scraping ${p.name}: $e');
    print(st);
    var file = new File('scrape/${p.name}.html');
    await file.create(recursive: true);
    await file.writeAsString(response?.body);
    return null;
  }
}

Politician scrapeReelectionFromVcard(Politician p, html.Document doc) {
  var $vcard = doc.querySelector('table.vcard');

  if ($vcard ==
      null) // Will never happen, because the 'Incumbent tag' is sourced from a v-card.
    return null;

  var $trs = $vcard.querySelectorAll('tr');

  bool scannedAssumed = false;

  for (var $tr in $trs) {
    if (!scannedAssumed) {
      var $tds = $tr.querySelectorAll('td');

      for (var $td in $tds) {
        if (!scannedAssumed) {
          var txt = $td.text.trim();
          if (scannedAssumed = txt.trim().startsWith(assumedOffice)) {
            var dateString = txt.replaceAll(assumedOffice, '').trim();
            var termStarted = dateFormat.parse(dateString);
            int termLength;

            switch (p.position) {
              case 'Representative':
                termLength = 2;
                break;
              case 'Senator':
                termLength = 6;
                break;
              case 'President':
                termLength = 4;
                break;
              default:
                print('Cannot determine term length for ${p.name}, a ${p
                    .position}.');
                return null;
            }

            int reelectionYear = termStarted.year + termLength - 1;

            while (reelectionYear <= now.year) reelectionYear += termLength;

            p.election = new ElectionInfo(
              month: 11,
              year: reelectionYear,
            );
          }
        }
      }
    } else {
      break;
    }
  }

  return p;
}

Future<Politician> scrapeEmailAndPhoneFromWebsite(
    Politician p, http.BaseClient client) async {
  if (p.website == null) return p;

  try {
    // Go to website root, try to fetch email and phone
    var response = await client.get(p.website);
    var emailMatch = email.firstMatch(response.body);
    var phoneMatch = phoneNumber.firstMatch(response.body);

    if (emailMatch != null) p.email = emailMatch[0];

    if (phoneNumber != null) p.phone = phoneMatch[0];

    if (p.email == null || p.phone == null) {
      // TODO: Find contact page, reliably
      response =
          await client.get(Uri.parse(p.website).replace(path: 'contact'));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        var emailMatch = email.firstMatch(response.body);
        var phoneMatch = phoneNumber.firstMatch(response.body);

        if (emailMatch != null) p.email = emailMatch[0];

        if (phoneNumber != null) p.phone = phoneMatch[0];
      }
    }

    if (p.email != null) print('Email for ${p.name}: ${p.email}');

    if (p.phone != null) print('Phone for ${p.name}: ${p.phone}');
  } catch (e) {
    // Remove broken website link
    p.website = null;
  } finally {
    return p;
  }
}
