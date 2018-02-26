import 'package:angel_client/angel_client.dart' show Service;
import 'package:angel_framework/angel_framework.dart' show Angel;
import 'package:angel_validate/angel_validate.dart';
import 'package:angel_test/angel_test.dart';
import 'package:blood_money/blood_money.dart';
import 'package:test/test.dart';

// Angel also includes facilities to make testing easier.
//
// `package:angel_test` ships a client that can test
// both plain HTTP and WebSockets.
//
// Tests do not require your server to actually be mounted on a port,
// so they will run faster than they would in other frameworks, where you
// would have to first bind a socket, and then account for network latency.
//
// See the documentation here:
// https://github.com/angel-dart/test
//
// If you are unfamiliar with Dart's advanced testing library, you can read up
// here:
// https://github.com/dart-lang/test

main() async {
  TestClient client;
  Service politicianService;

  setUp(() async {
    var app = new Angel();
    await app.configure(configureServer);

    client = await connectTo(app);
    politicianService = client.service('api/politicians');
  });

  tearDown(() async {
    await client.close();
  });

  var politicianValidator = new Validator({
    'name*,state*,tweet_id,phone,twitter': isString,
    'party*': isIn(['Democrat', 'Republican']),
    'email': isEmail,
    'website': matches(new RegExp(r'^https?://[^\n]+$')),
    'position*': anyOf(
      isIn(['Senator', 'Representative', 'President']),
      anyOf(
        // i.e. `Florida Senator`
        contains('Senator'),
        contains('Representative'),
      ),
    ),
    'money_from_nra': [
      isNum,
      greaterThanOrEqualTo(1.0),
    ],
    'election': new Validator({
      'month*': [
        isInt,
        greaterThanOrEqualTo(1),
        lessThanOrEqualTo(12),
      ],
      'year*': [
        isInt,
        greaterThanOrEqualTo(new DateTime.now().toUtc().year),
      ],
    }),
  });

  test('all politicians are valid', () async {
    var politicians = await politicianService.index();
    expect(
      politicians,
      allOf(
        isList,
        everyElement(politicianValidator),
      ),
    );
  });
}
