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
  bool _loading = false;

  PoliticianService(this.app) : service = app.service('api/politicians') {
    // Pre-load list of politicians asynchronously
    load();
  }

  bool get loading => _loading;

  // TODO: Cache in localStorage
  Future load() => reload();

  Future reload() async {
    try {
      _loading = true;
      Iterable<Politician> politicians =
          await service.index().then((it) => it.map(Politician.parse));
      this.items
        ..clear()
        ..addAll(politicians);
    } finally {
      _loading = false;
    }
  }

  Future<Politician> fetch(String id) =>
      service.read(id).then(Politician.parse);
}
