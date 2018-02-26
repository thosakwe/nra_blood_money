import 'dart:async';
import 'package:blood_money/models.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

final Uri recipsUrl = Uri.parse(
    'https://www.opensecrets.org/outsidespending/recips.php?cycle=2010&cmte=National%20Rifle%20Assn');

main() async {
  var client = new http.Client();
  var cycles = await getCycles(client);
  await Future.wait(cycles.map((cycle) => fetchFromCycle(cycle, client)));
  client.close();
}

/// Find all election cycles
///
/// i.e. `2010`, `2014`, etc.
Future<List<int>> getCycles(http.Client client) async {
  var response = await client.get(recipsUrl);
  var doc = html.parse(response.body);
  var $select = doc.querySelector('select[name="GoToPage"]');
  var $options = $select.querySelectorAll('option');

  return $options.map(($option) {
    return int.parse($option.text);
  }).toList();
}

Future<List<Politician>> fetchFromCycle(int cycle, http.Client client) async {
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
    // Parse name

    return new Politician(

    );
  }).toList();
}
