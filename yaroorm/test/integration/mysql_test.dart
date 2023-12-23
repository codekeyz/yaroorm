@Tags(['integration'])
import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/test_connections.dart';

final _driver = DatabaseDriver.init(mysqlConnection);

void main() {
  // group('MySQL', () {
  //   test('driver should connect', () async {
  //     await _driver.connect(secure: true);
  //
  //     expect(_driver.isOpen, isTrue);
  //   });
  //
  //   runIntegrationTest(_driver);
  // });
}
