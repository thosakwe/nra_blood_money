import 'package:angular/angular.dart';
import 'package:blood_money/models.dart';
import '../providers/politician_service.dart';

@Component(
    selector: 'politician-list',
    directives: const [COMMON_DIRECTIVES],
    template: '''
<div *ngIf="p.loading">Loading...</div>
<div *ngIf="!p.loading">Not loading lol</div>
''')
class PoliticianListComponent {
  final PoliticianService p;

  PoliticianListComponent(this.p);
}
