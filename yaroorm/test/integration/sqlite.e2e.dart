import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as db;
import 'base.dart';
import 'sqlite.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  group('SQLite', () => runIntegrationTest('foo_sqlite'));
}
