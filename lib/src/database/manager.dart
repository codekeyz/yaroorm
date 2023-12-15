import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import '../core/_config/config.dart';
import '../core/_container/container.dart';

class DB {
  static final List<DatabaseConnection> _connections = [];
  static final Map<String, DatabaseDriver> _driverInstances = {};

  late final List<Migration> migrations;
  late final DatabaseConnection defaultConn;

  static DB get instance {
    if (!isRegistered<DB>()) {
      throw Exception('Database Manager not initialized.');
    }
    return instanceFromRegistry<DB>();
  }

  static EntityTableInterface<Model> table<Model extends Entity>(String table) =>
      EntityTableInterface<Model>(table, driver: instance.defaultDriver);

  static DatabaseDriver driver(String connName) {
    final cached = _driverInstances[connName];
    if (cached != null) return cached;
    final connInfo = _connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) {
      throw Exception('No Database connection found with name: $connName');
    }
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  DB._(this.defaultConn) {
    _driverInstances[defaultConn.name] = DatabaseDriver.init(defaultConn);
  }

  DatabaseDriver get defaultDriver => _driverInstances[defaultConn.name]!;

  factory DB.init(ConfigResolver dbConfig) {
    final configuration = dbConfig.call();
    final defaultConn = configuration.getValue('default');
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
    _connections.addAll(connections);
    return registerSingleton<DB>(DB._(defaultConnection));
  }
}
