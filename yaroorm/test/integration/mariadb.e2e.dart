import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as db;
import 'e2e_basic.dart';
import 'e2e_relation.dart';
import 'mariadb.e2e.reflectable.dart';

void main() async {
  initializeReflectable();

  DB.init(db.config);

  group('MariaDB', () {
    group('Basic E2E Test', () => runBasicE2ETest('bar_mariadb'));

    group('Relation E2E Test', () => runRelationsE2ETest('bar_mariadb'));
  });
}
