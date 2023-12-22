import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/database/driver/mysql_driver.dart';
import 'package:yaroorm/src/database/driver/sqlite_driver.dart';

import 'helpers/drivers.dart';

void main() {
  group('DatabaseDriver.init', () {
    group('when sqlite connection', () {
      test('should return SQLite Driver', () {
        final driver = DatabaseDriver.init(sqliteConnection);
        expect(driver, isA<SqliteDriver>());

        expect(driver.type, DatabaseDriverType.sqlite);
      });

      test('should have table blueprint', () {
        final driver = DatabaseDriver.init(sqliteConnection);
        expect(driver, isA<SqliteDriver>());

        expect(driver.blueprint, isA<SqliteTableBlueprint>());
      });

      test('should have primitive serializer', () {
        final driver = DatabaseDriver.init(sqliteConnection);
        expect(driver, isA<SqliteDriver>());

        expect(driver.serializer, isA<SqliteSerializer>());
      });
    });

    group('when mysql connection', () {
      test('should return MySql Driver', () {
        final driver = DatabaseDriver.init(mysqlConnection);
        expect(driver, isA<MySqlDriver>());

        expect(driver.type, DatabaseDriverType.mysql);
      });

      test('should have table blueprint', () {
        final driver = DatabaseDriver.init(mysqlConnection);
        expect(driver, isA<MySqlDriver>());

        expect(driver.blueprint, isA<MySqlDriverTableBlueprint>());
      });

      test('should have primitive serializer', () {
        final driver = DatabaseDriver.init(mysqlConnection);
        expect(driver, isA<MySqlDriver>());

        expect(driver.serializer, isA<MySqlPrimitiveSerializer>());
      });
    });
  });
}
