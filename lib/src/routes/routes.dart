library blood_money.src.routes;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/file.dart';
import 'controllers/controllers.dart' as controllers;

/// Put your app routes here!
///
/// See the wiki for information about routing, requests, and responses:
/// * https://github.com/angel-dart/angel/wiki/Basic-Routing
/// * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
AngelConfigurer configureServer(FileSystem fs) {
  return (Angel app) async {
    // Typically, you want to mount controllers first, after any global middleware.
    await app.configure(controllers.configureServer);

    if (app.isProduction) {
      var publicDir = fs.directory('web/build/es5-bundled');
      var vDir =
          new CachingVirtualDirectory(app, fs, source: publicDir);
      //app.use(vDir.handleRequest);
      app.use(vDir.pushState('index.html', accepts: ['text/html']));
    } else {
      var vDir = new VirtualDirectory(app, fs);
      app.use(waterfall([
        vDir.handleRequest,
        vDir.pushState('index.html', accepts: ['text/html']),
      ]));
    }

    // Throw a 404 if no route matched the request.
    app.use(() => throw new AngelHttpException.notFound());
  };
}
