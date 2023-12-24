import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';

final _driver = DatabaseDriver.init(mysqlConnection);

void main() {
  setUpAll(() async {
    final driver = await _driver.connect(secure: true);
    print('We completed');

    assert(driver.isOpen, 'Driver is not open');
  });

  group('MySQL', () => runIntegrationTest(_driver));
}
