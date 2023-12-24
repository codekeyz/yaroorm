import 'dart:io';

import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';

final _driver = DatabaseDriver.init(mariadbConnection);

void main() {
  setUpAll(() async {
    await Process.run('sudo', [
      'mysql',
      '-e',
      "ALTER USER '${mariadbConnection.username}'@'${mariadbConnection.host}' IDENTIFIED BY '${mariadbConnection.password}'; FLUSH PRIVILEGES;"
    ]);

    await _driver.connect(secure: false);
  });

  group('MariaDB', () {
    test('driver should connect', () {
      expect(_driver.isOpen, isTrue);
    });

    runIntegrationTest(_driver);
  });
}
