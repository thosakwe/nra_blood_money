import 'dart:async';
import 'dart:html';
import 'package:angel_client/angel_client.dart';
import 'package:angular/angular.dart';
import 'package:blood_money/models.dart';

@Injectable()
class PoliticianService {
  static const String _key = 'politicians';
  final List<Politician> items = [];
  final Angel app;
  final Service service;

  PoliticianService(this.app) : service = app.service('api/politicians');

  // TODO: Cache in localStorage
  Future load() => reload();

  Future reload() async {
    Iterable<Politician> politicians =
        await service.index().then((it) => it.map(Politician.parse));
    this.items
      ..clear()
      ..addAll(politicians);
  }

  Future<Politician> fetch(String id) =>
      service.read(id).then(Politician.parse);
}
