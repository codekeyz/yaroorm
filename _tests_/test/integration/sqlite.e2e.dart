import 'package:test/test.dart';

import '../../database/database.dart';
import 'e2e_basic.dart';

void main() async {
  initializeORM();

  group('SQLite', () {
    group('Basic E2E Test', () => runBasicE2ETest('foo_sqlite'));

    // group('Relation E2E Test', () => runRelationsE2ETest('foo_sqlite'));
  });
}
