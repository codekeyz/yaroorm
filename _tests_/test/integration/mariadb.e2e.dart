import 'package:test/test.dart';

import '../../database/database.dart';
import 'e2e_basic.dart';

void main() async {
  initializeORM();

  group('MariaDB', () {
    group('Basic E2E Test', () => runBasicE2ETest('bar_mariadb'));

    // group('Relation E2E Test', () => runRelationsE2ETest('bar_mariadb'));
  });
}
