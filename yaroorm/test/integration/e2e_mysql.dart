import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/test_connections.dart';
import 'base.dart';

final _driver = DatabaseDriver.init(mysqlConnection);

void main() {
  setUpAll(() async => _driver.connect(secure: true));

  group('MySQL', () {
    test('driver should connect', () async {
      await _driver.connect(secure: true);

      expect(_driver.isOpen, isTrue);
    });

    try {
      runIntegrationTest(_driver);
    } catch (e) {
      print('Error: $e');
    }
  });
}
