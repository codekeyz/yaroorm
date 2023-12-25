import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';
import 'mariadb.e2e.reflectable.dart';

final _driver = DatabaseDriver.init(mariadbConnection);

void main() {
  setUpAll(() async {
    initializeReflectable();

    await Future.sync(() => _driver.connect(secure: false));
  });

  group('MariaDB', () => runIntegrationTest(_driver));
}
