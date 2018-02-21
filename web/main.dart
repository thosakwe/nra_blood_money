import 'package:angel_configuration/browser.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'components/blood_money.dart';

void main() {
  List providers = [
    ROUTER_PROVIDERS,
  ];

  if (config('debug')) {
    // Dev mode config
    providers.add(provide(LocationStrategy, useClass: HashLocationStrategy));
  } else {
    // Prod mode config
    providers.add(provide(APP_BASE_HREF, useValue: '/'));
  }

  bootstrap(BloodMoneyComponent, providers);
}
