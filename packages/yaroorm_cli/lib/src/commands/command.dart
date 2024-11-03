import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaroorm/yaroorm.dart' hide Table;
import '../misc/utils.dart';

import '../misc/migration.dart';

class MigrationDefn {
  late final String name;
  late final List<Schema> up, down;

  MigrationDefn(Migration migration) {
    name = migration.name;
    up = _accumulate(migration.name, migration.up);
    down = _accumulate(migration.name, migration.down);
  }

  List<Schema> _accumulate(String scriptName, void Function(List<Schema> schemas) func) {
    final result = <Schema>[];
    func(result);
    return result;
  }
}

final migrationLogTable = Table(
  header: ['Migration', 'Status'],
  columnWidths: [30, 30],
  style: TableStyle(header: ['green']),
);

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
    return (DB.migrations)
        .where((e) => e.connection == null || e.connection == dbConnection)
        .map(MigrationDefn.new)
        .toList();
  }

  @override
  FutureOr<int> run() async {
    if (ormConfig.connections.firstWhereOrNull((e) => e.name == dbConnection) == null) {
      logger.err('No connection named ${cyan.wrap(dbConnection)}');
      ExitCode.software.code;
    }

    Query.addTypeDef<MigrationEntity>(migrationentityTypeDef);

    final driver = DB.driver(dbConnection);
    await driver.connect();

    await execute(driver);

    await driver.disconnect();
    return ExitCode.success.code;
  }

  Future<void> execute(DatabaseDriver driver);
}
