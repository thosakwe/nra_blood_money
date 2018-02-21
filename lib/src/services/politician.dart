library blood_money.src.services.politician;

import 'package:angel_file_service/angel_file_service.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:file/file.dart';

AngelConfigurer configureServer(FileSystem fs) {
  return (Angel app) async {
    HookedService service = app.use(
      '/api/politicians',
      new JsonFileService(fs.file('db/politicians_db.json')),
    );

    // Read-only service. No endpoint is available to edit the data.
    service
      ..beforeModify(hooks.disable())
      ..beforeRemoved.listen(hooks.disable());
  };
}
