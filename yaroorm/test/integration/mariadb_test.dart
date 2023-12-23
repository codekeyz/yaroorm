@Tags(['mysql', 'mariadb'])
import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../unit/helpers/drivers.dart';
import 'base/integration_base.dart';

final driver = DatabaseDriver.init(mariadbConnection);

void main() {
  runIntegrationTest(driver);
}
