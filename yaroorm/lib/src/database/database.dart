library database;

import 'package:collection/collection.dart';
import 'package:grammer/grammer.dart';
import 'package:yaroorm/config.dart';
import 'package:yaroorm/yaroorm.dart';

class UseDatabaseConnection {
  final String name;
  late final DatabaseDriver _driver;

  UseDatabaseConnection(this.name) : _driver = DB.driver(name);

  Query<Result> query<Result>([String? table]) {
    if (table == null) {
      if (Result != Entity) {
        table = Result.toString().toPlural().first;
      } else {
        throw ArgumentError.notNull(table);
      }
    }
    return Query.table<Result>(table).driver(_driver);
  }
}

const String pleaseInitializeMessage = 'DB has not been initialized.\n'
    'Please make sure that you have called `DB.init(DatabaseConfig)`.';

class DB {
  /// This mapping contains the mirror-data for each reflector.
  /// It will be initialized in the generated code.
  static DatabaseConfig config = throw StateError(pleaseInitializeMessage);

  static final Map<String, DatabaseDriver> _driverInstances = {};

  static late final UseDatabaseConnection defaultConnection;

  DB._();

  static DatabaseDriver get defaultDriver => defaultConnection._driver;

  static Query<Result> query<Result extends Entity>([String? table]) {
    return defaultConnection.query<Result>(table);
  }

  static UseDatabaseConnection connection(String connName) => UseDatabaseConnection(connName);

  static DatabaseDriver driver(String connName) {
    if (connName == 'default') return defaultDriver;
    final instance = _driverInstances[connName];
    if (instance != null) return instance;
    final connInfo = config.connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) throw ArgumentError.value(connName, 'No Database connection found with name: $connName');
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  static void init(DatabaseConfig config) {
    DB.config = config;

    final defaultConn = config.defaultConnName;
    DB._driverInstances[defaultConn] = DatabaseDriver.init(config.defaultDBConn);
    DB.defaultConnection = UseDatabaseConnection(defaultConn);
  }
}
