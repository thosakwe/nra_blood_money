import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'landing.dart';
import 'politician_list.dart';

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
  const Route(
    path: '/list',
    name: 'List',
    component: PoliticianListComponent,
  ),
])
class BloodMoneyComponent {}
