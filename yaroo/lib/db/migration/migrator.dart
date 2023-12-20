// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:isolate';

import 'package:yaroo/db/db.dart';
import 'package:yaroo/src/_config/config.dart';
import 'package:yaroorm/yaroorm.dart';

import '_actions.dart';

export 'package:yaroorm/src/database/migration.dart';

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

class Migrator {
  /// commands
  static const String migrate = 'migrate';
  static const String migrateReset = 'migrate:reset';

  /// config keys for migrations
  static const migrationsTableNameKeyInConfig = 'migrationsTableName';
  static const migrationsKeyInConfig = 'migrations';

  static String _tableName = 'migrations';

  static String get tableName => _tableName;

  static final migrationsSchema = Schema.create('migrations', ($table) {
    return $table
      ..id()
      ..string('migration')
      ..integer('batch');
  });

  static Future<void> processCmd(String cmd, ConfigResolver dbConfig, {List<String>? cmdArguments}) async {
    /// validate config
    final config = dbConfig.call();
    final mgts = config[migrationsKeyInConfig];
    if (config.containsKey(migrationsTableNameKeyInConfig)) {
      final mgtsTableName = config[migrationsTableNameKeyInConfig];
      assert(mgtsTableName, '$migrationsTableNameKeyInConfig must be a String');
      Migrator._tableName = mgtsTableName!;
    }
    assert(mgts is Iterable<Migration>, 'Migrations must be an Iterable<Migration>');
    final migrations = (mgts as Iterable<Migration>).map((e) => _Task(e));

    /// resolve action for command
    final cmdAction = switch (cmd.toLowerCase()) {
      Migrator.migrate => () => doMigrateAction(migrations.map((e) => e.up)),
      Migrator.migrateReset => () => doResetMigrationAction(migrations.map((e) => e.down)),
      _ => throw UnsupportedError(cmd),
    };

    actualCb() async {
      DB.init(() => config);
      await cmdAction.call();
    }

    await Isolate.run(actualCb);
  }
}
