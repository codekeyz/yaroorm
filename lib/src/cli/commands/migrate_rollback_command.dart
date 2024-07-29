import 'dart:async';

import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';
import 'package:yaroorm/src/cli/logger.dart';
import '../../../yaroorm.dart' hide Table;

import '../_misc.dart';
import '../model/migration.dart';
import 'command.dart';

class MigrationRollbackCommand extends OrmCommand {
  static const String commandName = 'migrate:rollback';

  @override
  String get description => 'rollback last migration batch';

  @override
  String get name => commandName;

  @override
  Future<void> execute(DatabaseDriver driver) async {
    await ensureMigrationsTableReady(driver);

    final lastBatchNumber =
        await getLastBatchNumber(driver, migrationTableName);

    final entries = await MigrationEntityQuery.driver(driver)
        .where(
          (migration) => migration.batch(lastBatchNumber),
        )
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

    await processRollbacks(driver, [migrationTask], table: migrationLogTable);

    logger.write(migrationLogTable.toString());
  }
}

typedef Rollback = ({MigrationEntity entry, List<Schema> schemas});

Future<void> processRollbacks(
  DatabaseDriver driver,
  Iterable<Rollback> rollbacks, {
  Table? table,
}) async {
  for (final rollback in rollbacks) {
    await driver.transaction((transactor) async {
      for (var e in rollback.schemas) {
        await transactor.execute(e.toScript(driver.blueprint));
      }

      await MigrationEntityQuery.driver(transactor)
          .where(
            (migration) => migration.id(rollback.entry.id),
          )
          .delete();
    });

    table?.add([rollback.entry.migration, '✅ rolled back']);
  }
}
