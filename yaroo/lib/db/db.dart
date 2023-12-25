import 'package:collection/collection.dart';
import 'package:yaroo/src/config/database.dart';
import 'package:yaroorm/yaroorm.dart';

export 'package:yaroorm/src/database/entity.dart';
export 'package:yaroorm/src/database/migration.dart';

class UseDatabaseConnection {
  final String name;
  late final DatabaseDriver _driver;

  UseDatabaseConnection(this.name) : _driver = DB.driver(name);

  Query<Result> query<Result>(String table) => Query.table<Result>(table).driver(_driver);
}

class DB {
  static final List<DatabaseConnection> _connections = [];
  static final Map<String, DatabaseDriver> _driverInstances = {};

  static late final UseDatabaseConnection defaultConnection;
  static late final List<Migration> migrations;

  DB._();

  static DatabaseDriver get defaultDriver => defaultConnection._driver;

  static Query<Result> query<Result extends Entity>(String table) => defaultConnection.query<Result>(table);

  static UseDatabaseConnection connection(String connName) => UseDatabaseConnection(connName);

  static DatabaseDriver driver(String connName) {
    if (connName == 'default') return defaultDriver;
    final instance = _driverInstances[connName];
    if (instance != null) return instance;
    final connInfo = _connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) throw ArgumentError.value(connName, 'No Database connection found with name: $connName');
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  static void init(DatabaseConfig config) {
    DB._connections
      ..clear()
      ..addAll(config.connections);

    final defaultConn = config.defaultConnName;
    DB._driverInstances[defaultConn] = DatabaseDriver.init(config.defaultDBConn);
    DB.defaultConnection = UseDatabaseConnection(defaultConn);
  }
}
