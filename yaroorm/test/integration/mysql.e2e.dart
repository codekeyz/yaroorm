import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as db;
import 'base.dart';
import 'mysql.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  final driver = DB.driver('moo_mysql');

  await driver.connect(secure: true).timeout(const Duration(seconds: 5));

  group('MySQL', () => runIntegrationTest('moo_mysql', driver));
}
