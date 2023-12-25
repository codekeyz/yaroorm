import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../fixtures/connections.dart';
import 'base.dart';
import 'sqlite.e2e.reflectable.dart';

final driver = DatabaseDriver.init(sqliteConnection);

void main() {
  setUpAll(() async {
    initializeReflectable();

    final dbPath = path.absolute(sqliteConnection.database);
    final dbFile = File(dbPath);
    if (await dbFile.exists()) await dbFile.delete();
  });

  group('SQLite', () => runIntegrationTest(driver));
}
