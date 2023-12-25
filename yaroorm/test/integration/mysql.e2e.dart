import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';
import 'mysql.e2e.reflectable.dart';

final _driver = DatabaseDriver.init(mysqlConnection);

void main() {
  setUpAll(() async {
    initializeReflectable();
    
    await _driver.connect(secure: true).timeout(const Duration(seconds: 5));
  });

  group('MySQL', () => runIntegrationTest(_driver));
}
