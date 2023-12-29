import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as db;
import 'base.dart';
import 'mariadb.e2e.reflectable.dart';
void main() async {
  initializeReflectable();

  DB.init(db.config);

  final driver = DB.driver('bar_mariadb');

  await driver.connect(secure: false);

  group('MariaDB', () => runIntegrationTest('bar_mariadb', driver));
}
