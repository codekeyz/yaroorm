import 'package:collection/collection.dart';

import '../core/_config/config.dart';
import '../core/_container/container.dart';
import '../deps/yaroorm.dart';

class DatabaseManager {
  late final List<DatabaseConnection> connections;
  late final DatabaseConnection defaultConn;

  final Map<String, DatabaseDriver> _driverInstances = {};

  DatabaseDriver get defaultDriver => _driverInstances[defaultConn.name]!;

  DatabaseDriver getDriver(String connName) {
    final cached = _driverInstances[connName];
    if (cached != null) return cached;
    final connInfo = connections.firstWhere((e) => e.name == connName);
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  DatabaseManager._(this.connections, this.defaultConn) {
    _driverInstances[defaultConn.name] = DatabaseDriver.init(defaultConn);
  }

  static DatabaseManager get instance {
    if (!isRegistered<DatabaseManager>()) {
      throw Exception('Database Manager not initialized.');
    }
    return instanceFromRegistry<DatabaseManager>();
  }

  factory DatabaseManager.init(ConfigResolver dbConfig) {
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

    final instance = DatabaseManager._(connections.toList(), defaultConnection);
    return registerSingleton<DatabaseManager>(instance);
  }
}
