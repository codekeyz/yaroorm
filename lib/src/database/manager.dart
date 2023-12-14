import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import '../core/_config/config.dart';
import '../core/_container/container.dart';

class DBManager {
  late final List<DatabaseConnection> connections;
  late final DatabaseConnection defaultConn;

  final Map<String, DatabaseDriver> _driverInstances = {};

  static RecordQueryInterface<Model> query<Model extends Entity>({String? table}) {
    table ??= Model.runtimeType.toString().toLowerCase();
    return RecordQueryInterface<Model>(
      table,
      driver: DBManager.instance.defaultDriver,
    );
  }

  DatabaseDriver get defaultDriver => _driverInstances[defaultConn.name]!;

  DatabaseDriver getDriver(String connName) {
    final cached = _driverInstances[connName];
    if (cached != null) return cached;
    final connInfo = connections.firstWhere((e) => e.name == connName);
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  DBManager._(this.connections, this.defaultConn) {
    _driverInstances[defaultConn.name] = DatabaseDriver.init(defaultConn);
  }

  static DBManager get instance {
    if (!isRegistered<DBManager>()) {
      throw Exception('Database Manager not initialized.');
    }
    return instanceFromRegistry<DBManager>();
  }

  factory DBManager.init(ConfigResolver dbConfig) {
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

    final instance = DBManager._(connections.toList(), defaultConnection);
    return registerSingleton<DBManager>(instance);
  }
}
