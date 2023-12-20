import 'dart:isolate';

import 'package:yaroo/db/db.dart';
import 'package:yaroo/db/migration/_migrator.dart';
import 'package:yaroo/db/migration/_utils.dart';
import 'package:yaroo/src/_config/config.dart';
import 'package:yaroorm/yaroorm.dart';

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

  static Future<void> processCmd(String cmd, ConfigResolver dbConfig, {List<String> cmdArguments = const []}) async {
    /// validate config
    final config = dbConfig.call();
    var classes = config[Migrator.migrationsKeyInConfig];
    final connection = getValueFromCLIArs('database', cmdArguments) ?? config['default'];
    assert(connection.isNotEmpty, 'Database connection must be provided');
    if (config.containsKey(Migrator.migrationsTableNameKeyInConfig)) {
      final mgtsTableName = config[Migrator.migrationsTableNameKeyInConfig];
      assert(mgtsTableName, '${Migrator.migrationsTableNameKeyInConfig} value must be a String');
      Migrator.tableName = mgtsTableName!;
    }
    assert(classes is Iterable<Migration>, 'Migrations must be an Iterable<Migration>');

    final Iterable<Migration> migrationsForConnection =
        (classes).where((e) => getDBConnection(e, config) == connection);
    if (migrationsForConnection.isEmpty) {
      print('No migrations found for connection: $connection');
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
      DB.init(() => config);
      await cmdAction.call(DB.driver(connection));
    }

    await Isolate.run(isolatedTask);
  }
}
