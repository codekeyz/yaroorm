import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';
import 'fixtures/orm_config.dart' as db;

import 'e2e_basic.dart';
import 'pgsql.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  group('Postgres', () {
    group('Basic E2E Test', () => runBasicE2ETest('foo_pgsql'));
  });
}
