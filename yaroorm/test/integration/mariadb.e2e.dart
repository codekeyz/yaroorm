import 'dart:io';

import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';

final _driver = DatabaseDriver.init(mariadbConnection);

void main() {
  setUpAll(() async {
    final commands = [
      "CREATE USER '${mariadbConnection.username}'@'localhost' IDENTIFIED BY '${mariadbConnection.password}'",
      "GRANT ALL PRIVILEGES ON *.* TO '${mariadbConnection.username}'@'localhost'",
      "FLUSH PRIVILEGES"
    ];

    for (final command in commands) {
      final result = await Process.run('sudo', ['mysql', '-e', command]);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    }

    await _driver.connect(secure: false);
  });

  group('MariaDB', () {
    test('driver should connect', () {
      expect(_driver.isOpen, isTrue);
    });

    runIntegrationTest(_driver);
  });
}
