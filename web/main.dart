import 'package:angel_client/browser.dart';
import 'package:angel_configuration/browser.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'components/blood_money.dart';
import 'providers/providers.dart';

void main() {
  String basePath;
  List providers = [
    ROUTER_PROVIDERS,
    bloodMoneyProviders,
  ];

  if (config('debug')) {
    // Dev mode config
    basePath = 'http://localhost:3000';
    providers.add(provide(LocationStrategy, useClass: HashLocationStrategy));
  } else {
    // Prod mode config
    basePath = '/';
    providers.add(provide(APP_BASE_HREF, useValue: '/'));
  }

  providers.add(provide(Angel, useValue: new Rest(basePath)));

  bootstrap(BloodMoneyComponent, providers);
}
