import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/mysql_driver.dart';
import 'package:yaroorm/src/database/driver/pgsql_driver.dart';
import 'package:yaroorm/src/database/driver/sqlite_driver.dart';
import 'package:yaroorm/yaroorm.dart';

import 'integration/fixtures/orm_config.dart' as db;
import 'integration/fixtures/models.dart';

Matcher throwsArgumentErrorWithMessage(String message) =>
    throwsA(isA<ArgumentError>().having((p0) => p0.message, '', message));

void main() {
  Query.addTypeDef(userTypeData);

  setUpAll(() => DB.init(db.config));

  group('DatabaseDriver.init', () {
    group('when sqlite connection', () {
      late DatabaseDriver driver;

      setUpAll(() => driver = DB.driver('foo_sqlite'));

      test('should return SQLite Driver', () {
        expect(driver, isA<SqliteDriver>().having((p0) => p0.type, 'has driver type', DatabaseDriverType.sqlite));
      });

      test('should have table blueprint', () {
        expect(driver.blueprint, isA<SqliteTableBlueprint>());
      });

      test('should have primitive serializer', () {
        expect(driver.serializer, isA<SqliteSerializer>());
      });
    });

    group('when mysql connection', () {
      late DatabaseDriver driver;

      setUpAll(() => driver = DB.driver('moo_mysql'));

      test('should return MySql Driver', () {
        expect(driver, isA<MySqlDriver>().having((p0) => p0.type, 'has driver type', DatabaseDriverType.mysql));
      });

      test('should have table blueprint', () {
        expect(driver.blueprint, isA<MySqlDriverTableBlueprint>());
      });

      test('should have primitive serializer', () {
        expect(driver.serializer, isA<MySqlPrimitiveSerializer>());
      });
    });

    group('when mariadb connection', () {
      late DatabaseDriver driver;

      setUpAll(() => driver = DB.driver('bar_mariadb'));

      test('should return MySql Driver', () {
        expect(driver, isA<MySqlDriver>().having((p0) => p0.type, 'has driver type', DatabaseDriverType.mariadb));
      });

      test('should have table blueprint', () {
        expect(driver.blueprint, isA<MySqlDriverTableBlueprint>());
      });

      test('should have primitive serializer', () {
        expect(driver.serializer, isA<MySqlPrimitiveSerializer>());
      });
    });

    group('when postgres connection', () {
      late DatabaseDriver driver;

      setUpAll(() => driver = DB.driver('foo_pgsql'));

      test('should return Postgres Driver', () {
        expect(driver, isA<PostgreSqlDriver>().having((p0) => p0.type, 'has driver type', DatabaseDriverType.pgsql));
      });

      test('should have table blueprint', () {
        expect(driver.blueprint, isA<PgSqlTableBlueprint>());
      });

      test('should have primitive serializer', () {
        expect(driver.serializer, isA<PgSqlPrimitiveSerializer>());
      });
    });
  });

  test('should err when Query without driver', () async {
    late Object error;
    try {
      await Query.table<User>().all();
    } catch (e) {
      error = e;
    }

    expect(
      error,
      isA<StateError>()
          .having((p0) => p0.message, '', 'Driver not set for query. Make sure you supply a driver using .driver()'),
    );
  });
}
