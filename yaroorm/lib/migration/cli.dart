import 'dart:isolate';

import 'package:yaroorm/yaroorm.dart';

import '../migration.dart';
import 'migrator.dart';
import 'utils.dart';

export 'cli.dart';

typedef MigrationTask = ({String name, List<Schema> schemas});

typedef MigratorAction = Future<void> Function(DatabaseDriver driver);

class _Task {
  late final MigrationTask up, down;

  _Task(Migration migration) {
    up = (name: migration.name, schemas: _accumulate(migration.name, migration.up));
    down = (name: migration.name, schemas: _accumulate(migration.name, migration.down));
  }

  List<Schema> _accumulate(String scriptName, Function(List<Schema> schemas) func) {
    final result = <Schema>[];
    func(result);
    return result;
  }
}

class MigratorCLI {
  /// commands
  static const String migrate = 'migrate';
  static const String migrateReset = 'migrate:reset';
  static const String migrateRollback = 'migrate:rollback';

  static final migrationsSchema = Schema.create('migrations', ($table) {
    return $table
      ..id()
      ..string('migration')
      ..integer('batch');
  });

  static Future<void> processCmd(String cmd, {List<String> cmdArguments = const []}) async {
    final dbConfig = DB.config;

    var connectionNameFromArgs = getValueFromCLIArs('database', cmdArguments);
    if (connectionNameFromArgs != null) {
      if (!dbConfig.connections.any((e) => e.name == connectionNameFromArgs)) {
        throw ArgumentError(connectionNameFromArgs, 'No database connection found with name: $connectionNameFromArgs');
      }
    }

    final connectionToUse = connectionNameFromArgs ?? dbConfig.defaultConnName;
    Migrator.tableName = dbConfig.migrationsTable;

    final Iterable<Migration> migrationsForConnection = (dbConfig.migrations)
        .where((e) => (e.connection == 'default' ? dbConfig.defaultConnName : e.connection) == connectionToUse);
    if (migrationsForConnection.isEmpty) {
      print('No migrations found for connection: $connectionToUse');
      return;
    }

    final tasks = migrationsForConnection.map((e) => _Task(e));

    cmd = cmd.toLowerCase();
    final MigratorAction cmdAction = switch (cmd) {
      MigratorCLI.migrate => (driver) => Migrator.runMigrations(driver, tasks.map((e) => e.up)),
      MigratorCLI.migrateReset => (driver) => Migrator.resetMigrations(driver, tasks.map((e) => e.down)),
      MigratorCLI.migrateRollback => (driver) => Migrator.rollBackMigration(driver, tasks.map((e) => e.down)),
      _ => throw UnsupportedError(cmd),
    };

    isolatedTask() async {
      await cmdAction.call(DB.driver(connectionToUse));
    }

    await Isolate.run(isolatedTask);
  }
}
