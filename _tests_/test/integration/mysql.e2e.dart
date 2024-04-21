import 'package:test/test.dart';

import '../../database/database.dart';
import 'e2e_basic.dart';

void main() async {
  initializeORM();

  group('MySQL', () {
    group('Basic E2E Test', () => runBasicE2ETest('moo_mysql'));

    // group('Relation E2E Test', () => runRelationsE2ETest('moo_mysql'));
  });
}
