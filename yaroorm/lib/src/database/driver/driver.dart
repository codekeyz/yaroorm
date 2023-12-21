import '../../query/primitives/serializer.dart';
import '../../query/query.dart';
import '../migration.dart';
import 'sqlite_driver.dart';

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
      dbForeignKeys: connInfo['foreign_key_constraints'] ?? true,
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
    _ => throw ArgumentError.value(value, null, 'Invalid Database Driver provided in configuration')
  };
}

mixin DriverAble {
  /// Perform query on the database
  Future<List<Map<String, dynamic>>> query(Query query);

  /// Perform raw query on the database.
  Future<List<Map<String, dynamic>>> rawQuery(String script);

  /// Execute scripts on the database.
  ///
  /// Execution varies across drivers
  Future<void> execute(String script);

  /// Perform update on the database
  update(UpdateQuery query);

  /// Perform delete on the database
  delete(DeleteQuery query);

  insert(String tableName, Map<String, dynamic> data);
}

abstract class DriverTransactor with DriverAble {
  Future<List<Object?>> commit();

  @override
  void insert(String tableName, Map<String, dynamic> data);

  @override
  void update(UpdateQuery query);

  @override
  void delete(DeleteQuery query);
}

abstract interface class DatabaseDriver with DriverAble {
  factory DatabaseDriver.init(DatabaseConnection dbConn) {
    final driver = dbConn.driver;
    switch (driver) {
      case DatabaseDriverType.sqlite:
        return SqliteDriver(dbConn);
      default:
        throw ArgumentError.value(driver, null, 'Driver not yet supported');
    }
  }

  /// Check if the database is open for operation
  bool get isOpen;

  /// Schema name used to perform all write queries.
  DatabaseDriverType get type;

  /// Performs connection to the database.
  ///
  /// Depend on driver type it may create a connection pool.
  Future<DatabaseDriver> connect();

  /// Performs connection to the database.
  ///
  /// Depend on driver type it may create a connection pool.
  Future<void> disconnect();

  /// check if the table exists in the database
  Future<bool> hasTable(String tableName);

  @override
  Future<int> insert(String tableName, Map<String, dynamic> data);

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query);

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query);

  TableBlueprint get blueprint;

  PrimitiveSerializer get serializer;

  Future<void> transaction(void Function(DriverTransactor transactor) transaction);
}
