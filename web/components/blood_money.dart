import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'landing.dart';

@Component(
    selector: 'blood-money',
    template: '<router-outlet></router-outlet>',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(const [
  const Route(
    path: '/',
    name: 'Landing',
    component: LandingComponent,
  ),
])
class BloodMoneyComponent {}
