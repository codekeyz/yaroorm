import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';

final _driver = DatabaseDriver.init(mariadbConnection);

void main() {
  setUpAll(() => Future.sync(() => _driver.connect(secure: false)));

  group('MariaDB', () => runIntegrationTest(_driver));
}
