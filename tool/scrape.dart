import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:blood_money/models.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:isolate/load_balancer.dart';
import 'package:isolate/runner.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

final Uri recipsUrl = Uri.parse(
    'https://www.opensecrets.org/outsidespending/recips.php?cycle=2010&cmte=National%20Rifle%20Assn');

final Uri wikipediaIndex = Uri.parse('https://en.wikipedia.org/w/index.php');

final RegExp commaOrSpace = new RegExp(r'[, ]');

final RegExp moneyValid = new RegExp(r'[0-9,.]+');

main() async {
  var client = new http.Client();
  var cycles = await getCycles(client);
  var pool = await LoadBalancer.create(
      Platform.numberOfProcessors, IsolateRunner.spawn);

  /*
  var scrapeTasks = cycles.map((cycle) {
    return pool.run(fetchFromCycle, cycle);
  });
  */

  var scrapeTasks = [pool.run(fetchFromCycle, 2016)];

  var polticians = await Future
      .wait(scrapeTasks)
      .then<List<Politician>>((list) => list.reduce((a, b) => a..addAll(b)));

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
        name: '${names[1]} ${names[0]}',
        party: $tds[1].text == 'D' ? 'Democrat' : 'Republican',
        state: $tds[2].text,
        position: guessPosition($tds[3].text.trim()),
        createdAt: now,
        updatedAt: now,
      );

      if (p.state.isEmpty) p.state = 'USA';

      // Get rid of "three-name" situations
      if (names.length == 3) {
        p.name = '${names[1]} ${names[0]}';
        //print('$names - ${names.length}');
      }

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
    var redirect = response.headers['location'];
    //print('${p.name} -> $redirect');

    // TODO: Find correct link on sports page
    var doc = html.parse(response.body);

    p.imageUrl = 'https:' +
        doc
            .querySelectorAll('a.image')[0]
            .querySelector('img')
            .attributes['src'];

    return p;
  } catch (e, st) {
    print('Error: ${p.name} - $e');
    print(st);
    var file = new File('scrape/${p.name}.html');
    await file.create(recursive: true);
    await file.writeAsString(response?.body);
    return null;
  }
}
