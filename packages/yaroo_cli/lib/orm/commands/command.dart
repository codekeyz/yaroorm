import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:yaroorm/migration.dart';
import 'package:yaroorm/yaroorm.dart';

class MigrationDefn {
  late final String name;
  late final List<Schema> up, down;

  MigrationDefn(Migration migration) {
    name = migration.name;
    up = _accumulate(migration.name, migration.up);
    down = _accumulate(migration.name, migration.down);
  }

  List<Schema> _accumulate(
    String scriptName,
    Function(List<Schema> schemas) func,
  ) {
    final result = <Schema>[];
    func(result);
    return result;
  }
}

abstract class OrmCommand extends Command<int> {
  static const String connectionArg = 'connection';

  YaroormConfig get ormConfig => DB.config;

  String get migrationTableName => ormConfig.migrationsTable;

  String get dbConnection {
    final defaultConn = ormConfig.defaultConnName;
    final args = globalResults;
    if (args == null) return defaultConn;
    return args.wasParsed(OrmCommand.connectionArg) ? args[OrmCommand.connectionArg] : defaultConn;
  }

  List<MigrationDefn> get migrationDefinitions {
    return (ormConfig.migrations)
        .where((e) => e.connection == null || e.connection == dbConnection)
        .map(MigrationDefn.new)
        .toList();
  }

  @override
  FutureOr<int> run() async {
    final driver = DB.driver(dbConnection);
    await driver.connect();

    await execute(driver);

    await driver.disconnect();
    return 0;
  }

  Future<void> execute(DatabaseDriver driver);
}
