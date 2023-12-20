import 'dart:isolate';

import 'package:yaroo/db/db.dart';
import 'package:yaroo/db/migration/_migrator.dart';
import 'package:yaroo/src/_config/config.dart';
import 'package:yaroorm/yaroorm.dart';

typedef MigrationTask = ({String name, DatabaseDriver driver, List<Schema> schemas});

class _Task {
  late final MigrationTask up, down;
  late final DatabaseDriver driver;

  _Task(Migration migration) : driver = DB.driver(migration.connection) {
    up = (name: migration.name, driver: driver, schemas: _accumulate(migration.name, migration.up));
    down = (name: migration.name, driver: driver, schemas: _accumulate(migration.name, migration.down));
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

  static final migrationsSchema = Schema.create('migrations', ($table) {
    return $table
      ..id()
      ..string('migration')
      ..integer('batch');
  });

  static Future<void> processCmd(String cmd, ConfigResolver dbConfig, {List<String>? cmdArguments}) async {
    /// validate config
    final config = dbConfig.call();
    final mgts = config[Migrator.migrationsKeyInConfig];
    if (config.containsKey(Migrator.migrationsTableNameKeyInConfig)) {
      final mgtsTableName = config[Migrator.migrationsTableNameKeyInConfig];
      assert(mgtsTableName, '${Migrator.migrationsTableNameKeyInConfig} value must be a String');
      Migrator.tableName = mgtsTableName!;
    }
    assert(mgts is Iterable<Migration>, 'Migrations must be an Iterable<Migration>');
    final files = (mgts as Iterable<Migration>).map((e) => _Task(e));

    /// resolve action for command
    cmd = cmd.toLowerCase();
    final cmdAction = switch (cmd) {
      MigratorCLI.migrate => () => Migrator.runMigrations(files.map((e) => e.up)),
      MigratorCLI.migrateReset => () => Migrator.resetMigrations(files.map((e) => e.down)),
      _ => throw UnsupportedError(cmd),
    };

    isolatedTask() async {
      DB.init(() => config);
      await cmdAction.call();
    }

    await Isolate.run(isolatedTask);
  }
}
