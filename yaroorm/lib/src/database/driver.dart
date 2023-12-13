import 'package:collection/collection.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../config/config.dart';

typedef DatabaseConfig = Map<String, dynamic>;

enum DatabaseDriverType { sqlite, pgsql, mongo }

class DatabaseConfiguration {
  final String? url;
  final String? host;
  final String? port;
  final String? username;
  final String? password;
  final String database;
  final String? charset, collation;
  final DatabaseDriverType driver;

  const DatabaseConfiguration(
    this.database,
    this.driver, {
    this.charset,
    this.collation,
    this.host,
    this.password,
    this.port,
    this.url,
    this.username,
  });

  factory DatabaseConfiguration.from(Map<String, dynamic> connInfo) {
    return DatabaseConfiguration(
      connInfo.getValue<String>('database')!,
      _getDriverType(connInfo),
      charset: connInfo['charset'],
      collation: connInfo['collation'],
      host: connInfo['host'],
      port: connInfo['port'],
      password: connInfo['password'],
      username: connInfo['username'],
      url: connInfo['url'],
    );
  }
}

DatabaseDriverType _getDriverType(Map<String, dynamic> connInfo) {
  final value = connInfo.getValue('driver');
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
  factory DatabaseDriver.init(DatabaseConfig config) {
    final defaultConn = config.getValue('default');
    if (defaultConn == null) {
      throw ArgumentError.notNull('Default Database Connection');
    }

    final connections = config.getValue<Map<String, dynamic>>('connections') ?? {};
    final connInfo =
        connections.entries.firstWhereOrNull((e) => e.key == defaultConn)?.value;
    if (connInfo == null) {
      throw ArgumentError('No Connection info found for $defaultConn');
    }

    final dbConfig = DatabaseConfiguration.from(connInfo);
    final driver = dbConfig.driver;

    switch (driver) {
      case DatabaseDriverType.sqlite:
        return SqliteDriver(dbConfig);
      default:
        throw ArgumentError.value(driver, null, 'Driver not yet supported');
    }
  }

  /// Database name used to perform all write queries.
  String get database;

  /// Schema name used to perform all write queries.
  String get scheme;

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
}

class SqliteDriver implements DatabaseDriver {
  final DatabaseConfiguration config;

  Database? _database;

  SqliteDriver(this.config);

  @override
  Future<void> connect() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    _database = await databaseFactory.openDatabase(config.database);
  }

  @override
  String get database => throw UnimplementedError();

  @override
  Future<void> disconnect() async {
    if (_database?.isOpen != true) return;
    await _database!.close();
  }

  @override
  String get scheme => config.database;

  @override
  DatabaseDriverType get type => DatabaseDriverType.sqlite;
}
