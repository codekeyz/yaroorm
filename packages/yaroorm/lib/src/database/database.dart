library database;

import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

class UseDatabaseConnection {
  final DatabaseConnection info;
  late final DatabaseDriver driver;

  UseDatabaseConnection(this.info) : driver = DB.driver(info.name);

  Query<Model> query<Model extends Entity>([String? table]) {
    return Query.table<Model>(table).driver(driver)..database = info.database;
  }
}

const String pleaseInitializeMessage = 'DB has not been initialized.\n'
    'Please make sure that you have called `DB.init(DatabaseConfig)`.';

class DB {
  static YaroormConfig config = throw StateError(pleaseInitializeMessage);

  static final Map<String, DatabaseDriver> _driverInstances = {};

  static late final UseDatabaseConnection defaultConnection;

  DB._();

  static DatabaseDriver get defaultDriver => defaultConnection.driver;

  static Query<Model> query<Model extends Entity>([String? table]) =>
      defaultConnection.query<Model>(table);

  static UseDatabaseConnection connection(String connName) =>
      UseDatabaseConnection(
          config.connections.firstWhere((e) => e.name == connName));

  /// This call returns the driver for a connection
  ///
  /// [connName] is the connection name you defined in [YaroormConfig]
  static DatabaseDriver driver(String connName) {
    if (connName == 'default') return defaultDriver;
    final instance = _driverInstances[connName];
    if (instance != null) return instance;
    final connInfo =
        config.connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) {
      throw ArgumentError.value(
        connName,
        'No Database connection found with name: $connName',
      );
    }
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  static void init(YaroormConfig config) {
    DB.config = config;

    final defaultConn = config.defaultDBConn;
    DB._driverInstances[defaultConn.name] = DatabaseDriver.init(defaultConn);
    DB.defaultConnection = UseDatabaseConnection(defaultConn);
  }
}
