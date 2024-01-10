import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as db;
import 'e2e_basic.dart';
import 'e2e_relation.dart';

import 'sqlite.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  group('SQLite', () {
    group('Basic E2E Test', () => runBasicE2ETest('foo_sqlite'));

    group('Relation E2E Test', () => runRelationsE2ETest('foo_sqlite'));
  });
}
