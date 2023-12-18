import 'package:zomato/zomato.dart';

import '../config/app.dart' as a1;
import '../config/database.dart' as db;
import 'zomato.reflectable.dart';

final zomatoApp = ZomatoApp(a1.appConfig, dbConfig: db.config);

void main(List<String> arguments) async {
  initializeReflectable();

  await zomatoApp.bootstrap();
}
