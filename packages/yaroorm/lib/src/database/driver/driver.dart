import 'package:yaroorm/src/database/driver/mysql_driver.dart';
import 'package:yaroorm/src/database/driver/pgsql_driver.dart';

import '../../primitives/serializer.dart';
import '../../query/query.dart';
import '../../../migration.dart';

import '../entity/entity.dart';
import 'sqlite_driver.dart';

enum DatabaseDriverType { sqlite, pgsql, mysql, mariadb }

String wrapString(String value) => "'$value'";

class DatabaseConnection {
  final String name;
  final String? url;
  final String? host;
  final int? port;
  final String? username;
  final String? password;
  final String database;
  final String? charset, collation;
  final bool dbForeignKeys;
  final DatabaseDriverType driver;
  final bool? secure;
  final String timeZone;

  const DatabaseConnection(
    this.name,
    this.driver, {
    required this.database,
    this.charset,
    this.collation,
    this.host,
    this.password,
    this.port,
    this.url,
    this.username,
    this.dbForeignKeys = true,
    this.secure,
    this.timeZone = 'UTC',
  });

  factory DatabaseConnection.fromJson(Map<String, dynamic> connInfo) {
    return DatabaseConnection(
      connInfo['name'],
      getDriverType(connInfo['driver']),
      database: connInfo['database'],
      host: connInfo['host'],
      port: connInfo['port'] == null ? null : int.tryParse(connInfo['port']),
      charset: connInfo['charset'],
      collation: connInfo['collation'],
      password: connInfo['password'],
      username: connInfo['username'],
      url: connInfo['url'],
      secure: connInfo['secure'],
      dbForeignKeys: connInfo['foreign_key_constraints'] ?? true,
      timeZone: connInfo['timezone'] ?? 'UTC',
    );
  }

  static DatabaseDriverType getDriverType(String driver) {
    return switch (driver) {
      'sqlite' => DatabaseDriverType.sqlite,
      'pgsql' => DatabaseDriverType.pgsql,
      'mysql' => DatabaseDriverType.mysql,
      'mariadb' => DatabaseDriverType.mariadb,
      _ => throw ArgumentError.value(driver, null, 'Invalid Database Driver provided in configuration')
    };
  }
}

mixin DriverContract {
  /// Perform query on the database
  Future<List<Map<String, dynamic>>> query(Query query);

  /// Perform raw query on the database.
  Future<List<Map<String, dynamic>>> rawQuery(String script);

  /// Execute scripts on the database.
  ///
  /// Execution varies across drivers
  Future<dynamic> execute(String script);

  /// Perform update on the database
  Future<void> update(UpdateQuery query);

  /// Perform delete on the database
  Future<void> delete(DeleteQuery query);

  /// Perform insert on the database
  Future<dynamic> insert(InsertQuery query);

  /// Perform insert on the database
  Future<dynamic> insertMany(InsertManyQuery query);

  PrimitiveSerializer get serializer;

  List<EntityTypeConverter> get typeconverters => [];
}

abstract class DriverTransactor with DriverContract {}

abstract interface class DatabaseDriver with DriverContract {
  factory DatabaseDriver.init(DatabaseConnection dbConn) {
    final driver = dbConn.driver;
    switch (driver) {
      case DatabaseDriverType.sqlite:
        return SqliteDriver(dbConn);
      case DatabaseDriverType.mariadb:
      case DatabaseDriverType.mysql:
        return MySqlDriver(dbConn, driver);
      case DatabaseDriverType.pgsql:
        return PostgreSqlDriver(dbConn);
    }
  }

  /// Check if the database is open for operation
  bool get isOpen;

  /// Schema name used to perform all write queries.
  DatabaseDriverType get type;

  /// Performs connection to the database.
  ///
  /// Depend on driver type it may create a connection pool.
  Future<DatabaseDriver> connect({int? maxConnections, bool? singleConnection});

  /// Performs connection to the database.
  ///
  /// Depend on driver type it may create a connection pool.
  Future<void> disconnect();

  /// check if the table exists in the database
  Future<bool> hasTable(String tableName);

  TableBlueprint get blueprint;

  Future<void> transaction(void Function(DriverTransactor transactor) transaction);
}
