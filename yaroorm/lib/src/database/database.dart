library database;

import 'package:collection/collection.dart';
import 'package:yaroorm/config.dart';
import 'package:yaroorm/yaroorm.dart';

class UseDatabaseConnection {
  final String name;
  late final DatabaseDriver _driver;

  UseDatabaseConnection(this.name) : _driver = DB.driver(name);

  Query<Model> query<Model extends Entity>([String? table]) => Query.table<Model>(table).driver(_driver);
}

const String pleaseInitializeMessage = 'DB has not been initialized.\n'
    'Please make sure that you have called `DB.init(DatabaseConfig)`.';

class DB {
  static YaroormConfig config = throw StateError(pleaseInitializeMessage);

  static final Map<String, DatabaseDriver> _driverInstances = {};

  static late final UseDatabaseConnection defaultConnection;

  DB._();

  static DatabaseDriver get defaultDriver => defaultConnection._driver;

  static Query<Result> query<Result extends Entity>([String? table]) => defaultConnection.query<Result>(table);

  static UseDatabaseConnection connection(String connName) => UseDatabaseConnection(connName);

  /// This call returns the driver for a connection
  ///
  /// [connName] is the connection name you defined in [YaroormConfig]
  static DatabaseDriver driver(String connName) {
    if (connName == 'default') return defaultDriver;
    final instance = _driverInstances[connName];
    if (instance != null) return instance;
    final connInfo = config.connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) throw ArgumentError.value(connName, 'No Database connection found with name: $connName');
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  static void init(YaroormConfig config) {
    DB.config = config;

    final defaultConn = config.defaultConnName;
    DB._driverInstances[defaultConn] = DatabaseDriver.init(config.defaultDBConn);
    DB.defaultConnection = UseDatabaseConnection(defaultConn);
  }
}
