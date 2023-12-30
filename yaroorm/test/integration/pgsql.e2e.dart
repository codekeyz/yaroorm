@Tags(['integration'])
import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';
import '../fixtures/orm_config.dart' as db;
import 'base.dart';
import 'pgsql.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  final driver = DB.driver('foo_pgsql');

  await driver
      .connect(
        secure: true,
      )
      .timeout(const Duration(seconds: 60));

  group('description', () => runIntegrationTest('foo_pgsql', driver));
}
