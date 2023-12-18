import 'package:yaroo/yaroo.dart';

export 'package:zomato/src/providers/providers.dart';

class ZomatoApp extends ApplicationFactory {
  ZomatoApp(
    super.appConfig, {
    super.dbConfig,
  });
}
