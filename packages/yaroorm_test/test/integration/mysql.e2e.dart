import 'package:test/test.dart';

import '../../database/database.dart' as db;
import 'e2e_basic.dart';
import 'e2e_relation.dart';

void main() async {
  db.initializeORM();

  group('MySQL', () {
    group('Basic E2E Test', () => runBasicE2ETest('moo_mysql'));

    group('Relation E2E Test', () => runRelationsE2ETest('moo_mysql'));
  });
}
