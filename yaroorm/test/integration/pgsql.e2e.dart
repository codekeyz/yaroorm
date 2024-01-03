import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';
import '../fixtures/orm_config.dart' as db;
import 'base.dart';
import 'pgsql.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  group('Postgres', () => runIntegrationTest('foo_pgsql'));
}
