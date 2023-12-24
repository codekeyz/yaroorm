import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';

final _driver = DatabaseDriver.init(mysqlConnection);

void main() {
  setUpAll(() => Future.sync(() => _driver.connect(secure: true)));

  group('MySQL', () => runIntegrationTest(_driver));
}
