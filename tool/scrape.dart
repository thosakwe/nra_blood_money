import 'dart:async';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

final Uri recipsUrl = Uri.parse(
    'https://www.opensecrets.org/outsidespending/recips.php?cycle=2010&cmte=National%20Rifle%20Assn');

main() async {
  var client = new http.Client();
  var cycles = await getCycles(client);
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
