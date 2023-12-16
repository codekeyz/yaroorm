import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import '../core/_config/config.dart';

class UseDatabaseConnection {
  final String connection;
  late final DatabaseDriver _driver;
  UseDatabaseConnection(this.connection) : _driver = DB.driver(connection);

  ReadOperation<Model> read<Model extends Entity>(String table) {
    return ReadQuery<Model>(table, _driver);
  }

  UpdateOperation<Model> update<Model extends Entity>(String table) {
    return UpdateQuery<Model>(table, _driver);
  }
}

class DB {
  static final List<DatabaseConnection> _connections = [];
  static final Map<String, DatabaseDriver> _driverInstances = {};

  static late final String defaultConn;
  static late final List<Migration> migrations;

  DB._();

  static DatabaseDriver get defaultDriver => driver(defaultConn);

  static ReadOperation<Model> read<Model extends Entity>(String table) =>
      UseDatabaseConnection(defaultConn).read(table);

  static UpdateOperation<Model> update<Model extends Entity>(String table) =>
      UseDatabaseConnection(defaultConn).update(table);

  static UseDatabaseConnection connection(String connName) =>
      UseDatabaseConnection(connName);

  static DatabaseDriver driver(String connName) {
    final cached = _driverInstances[connName];
    if (cached != null) return cached;
    final connInfo = _connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) {
      throw Exception('No Database connection found with name: $connName');
    }
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  static void init(ConfigResolver dbConfig) {
    final configuration = dbConfig.call();
    final defaultConn = configuration.getValue<String>('default');
    if (defaultConn == null) {
      throw ArgumentError.notNull('Default database connection');
    }
    final connInfos = configuration.getValue<Map<String, dynamic>>('connections');
    if (connInfos == null || connInfos.isEmpty) {
      throw ArgumentError('Database connection infos not provided');
    }
    final connections =
        connInfos.entries.map((e) => DatabaseConnection.from(e.key, e.value));
    final defaultConnection = connections.firstWhereOrNull((e) => e.name == defaultConn);
    if (defaultConnection == null) {
      throw ArgumentError('Database connection info not found for $defaultConn');
    }

    DB._connections
      ..clear()
      ..addAll(connections);

    DB.defaultConn = defaultConn;
    DB._driverInstances[defaultConn] = DatabaseDriver.init(defaultConnection);
  }
}
