import 'dart:async';
import 'dart:io';
import 'package:blood_money/models.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:isolate/load_balancer.dart';
import 'package:isolate/runner.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

final Uri recipsUrl = Uri.parse(
    'https://www.opensecrets.org/outsidespending/recips.php?cycle=2010&cmte=National%20Rifle%20Assn');

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

  polticians.forEach((p) => print(p.toJson()));

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

    return $trs.map(($tr) {
      var $tds = $tr.querySelectorAll('td');

      // Parse name
      var names = $tds[0].text.split(',').map((s) => s.trim()).toList();

      return new Politician(
        name: '${names[1]} ${names[0]}',
        party: $tds[1].text == 'D' ? 'Democrat' : 'Republican',
      );
    }).toList();
  } finally {
    client.close();
  }
}
