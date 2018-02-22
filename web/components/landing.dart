import 'package:angular/angular.dart';

@Component(
    selector: 'landing-page',
    template: '''
<section class="hero is-dark is-bold is-fullheight">
  <div id="backdrop"></div>
  <div class="hero-body">
    <div class="container">
      <h1 class="title">
        #VoteThemOut.
      </h1>
      <h2 class="subtitle">
        NRA-hugging politicians <strong>refuse</strong> to act as innocents die.
      </h2>
      <a class="button is-dark is-inverted is-outlined">
        See who's taking blood money &gt;
      </a>
    </div>
  </div>
</section>
''',
    styles: const [
      '''
#backdrop {
  background-image: url('/images/140417-poulos-guns-money-tease_l6iyi8.jpeg');
  background-size: cover;
  height: 100%;
  width: 100%;
  position: absolute;
  opacity: 0.2;
}
''',
    ])
class LandingComponent {}
