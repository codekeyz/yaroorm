import 'dart:async';

import 'package:collection/collection.dart';
import 'package:yaroorm/migration.dart';
import 'package:yaroorm/yaroorm.dart';

import '../orm.dart';
import 'command.dart';

class MigrationRollbackCommand extends OrmCommand {
  @override
  String get description => 'rollback last migration batch';

  @override
  String get name => 'migrate:rollback';

  @override
  Future<void> execute(DatabaseDriver driver) async {
    await ensureMigrationsTableReady(driver);

    final lastBatchNumber =
        await getLastBatchNumber(driver, migrationTableName);

    final entries = await DB
        .connection(dbConnection)
        .query<MigrationData>(migrationTableName)
        .whereEqual('batch', lastBatchNumber)
        .findMany();

    /// rollbacks start from the last class listed in the migrations list
    final migrationTask = migrationDefinitions
        .map((defn) {
          final entry =
              entries.firstWhereOrNull((e) => e.migration == defn.name);
          return entry == null ? null : (entry: entry, schemas: defn.down);
        })
        .whereNotNull()
        .lastOrNull;

    if (migrationTask == null) {
      print('𐄂 skipped: reason:     no migration to rollback');
      return;
    }

    print(
        '------- Rolling back ${migrationTask.entry.migration}  📦 -------\n');

    await processRollbacks(driver, [migrationTask]);

    print('\n------- Rollback done 🚀 -------\n');
  }
}

typedef Rollback = ({MigrationData entry, List<Schema> schemas});

Future<void> processRollbacks(
    DatabaseDriver driver, Iterable<Rollback> rollbacks) async {
  for (final rollback in rollbacks) {
    await driver.transaction((transactor) async {
      for (var e in rollback.schemas) {
        await transactor.execute(e.toScript(driver.blueprint));
      }

      await Query.table(
        DB.config.migrationsTable,
      ).driver(transactor).whereEqual('id', rollback.entry.id!).delete();
    });

    print('✔ rolled back: ${rollback.entry.migration}');
  }
}
