import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as db;
import 'base.dart';
import 'sqlite.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  final driver = DB.driver('foo_sqlite');

  await driver.connect();

  group('SQLite', () => runIntegrationTest(driver));
}
