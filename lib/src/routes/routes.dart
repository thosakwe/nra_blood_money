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
AngelConfigurer configureServer(FileSystem fileSystem) {
  return (Angel app) async {
    // Typically, you want to mount controllers first, after any global middleware.
    await app.configure(controllers.configureServer);

    if (app.isProduction) {
      var publicDir = fileSystem.directory('build/web');
      var indexHtml = publicDir.childFile('index.html');

      app.use((RequestContext req, ResponseContext res) async {
        if (!req.accepts('text/html', strict: true))
          return true;
        res.headers['content-type'] = 'text/html';
        await indexHtml.openRead().pipe(res);
      });
    }

    // Throw a 404 if no route matched the request.
    app.use(() => throw new AngelHttpException.notFound());
  };
}
