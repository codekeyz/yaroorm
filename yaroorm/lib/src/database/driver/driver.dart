import '../../query/primitives.dart';
import '../../query/query.dart';
import '../database.dart';
import 'sqlite_driver.dart';

typedef DatabaseConfig = Map<String, dynamic>;

enum DatabaseDriverType { sqlite, pgsql, mongo }

class DatabaseConnection {
  final String name;
  final String? url;
  final String? host;
  final String? port;
  final String? username;
  final String? password;
  final String database;
  final String? charset, collation;
  final bool dbForeignKeys;
  final DatabaseDriverType driver;

  const DatabaseConnection(
    this.name,
    this.database,
    this.driver, {
    this.charset,
    this.collation,
    this.host,
    this.password,
    this.port,
    this.url,
    this.username,
    this.dbForeignKeys = true,
  });

  factory DatabaseConnection.from(String name, Map<String, dynamic> connInfo) {
    return DatabaseConnection(
      name,
      connInfo['database'],
      _getDriverType(connInfo),
      charset: connInfo['charset'],
      collation: connInfo['collation'],
      host: connInfo['host'],
      port: connInfo['port'],
      password: connInfo['password'],
      username: connInfo['username'],
      url: connInfo['url'],
      dbForeignKeys: connInfo['foreign_key_constraints'],
    );
  }
}

DatabaseDriverType _getDriverType(Map<String, dynamic> connInfo) {
  final value = connInfo['driver'];
  return switch (value) {
    'sqlite' => DatabaseDriverType.sqlite,
    'pgsql' => DatabaseDriverType.pgsql,
    'mongo' => DatabaseDriverType.mongo,
    null => throw ArgumentError.notNull('Database Driver'),
    _ => throw ArgumentError.value(
        value, null, 'Invalid Database Driver provided in configuration')
  };
}

abstract interface class DatabaseDriver {
  factory DatabaseDriver.init(DatabaseConnection dbConn) {
    final driver = dbConn.driver;
    switch (driver) {
      case DatabaseDriverType.sqlite:
        return SqliteDriver(dbConn);
      default:
        throw ArgumentError.value(driver, null, 'Driver not yet supported');
    }
  }

  /// Database name used to perform all write queries.
  String get database;

  /// Check if the database is open for operation
  bool get isOpen;

  /// Schema name used to perform all write queries.
  DatabaseDriverType get type;

  /// Performs connection to the database.
  ///
  /// Depend on driver type it may create a connection pool.
  Future<void> connect();

  /// Performs connection to the database.
  ///
  /// Depend on driver type it may create a connection pool.
  Future<void> disconnect();

  TableBlueprint get blueprint;

  QueryPrimitiveSerializer get querySerializer;

  Future<T> query<T extends Entity>(RecordQueryInterface<T> query);

  /// Execute scripts on the database.
  ///
  /// Execution varies across drivers
  Future<dynamic> execute(String script);
}
