library blood_money;

import 'dart:async';
import 'package:angel_cors/angel_cors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'src/config/config.dart' as configuration;
import 'src/routes/routes.dart' as routes;
import 'src/services/services.dart' as services;

const FileSystem fs = const LocalFileSystem();

/// Configures the server instance.
Future configureServer(Angel app) async {
  // Enable CORS
  // app.use(cors());

  // Set up our application, using the plug-ins defined with this project.
  await app.configure(configuration.configureServer(fs));
  await app.configure(services.configureServer(fs));
  await app.configure(routes.configureServer(fs));
}
