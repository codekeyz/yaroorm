import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import 'migrator.dart';
import 'utils.dart';

class _MigrationDbData {
  final int id;
  final String migration;
  final int batch;

  const _MigrationDbData(this.id, this.migration, this.batch);

  static _MigrationDbData from(Map<String, dynamic> data) {
    return _MigrationDbData(data['id'], data['migration'], data['batch']);
  }
}

typedef MigrationTask = ({String name, DatabaseDriver driver, List<Schema> schemas});

Future<void> doMigrateAction(Iterable<MigrationTask> migrations) async {
  print('------- Starting DB migration  📦 -------\n');

  int? batchNos;

  for (final migration in migrations) {
    final driver = migration.driver;
    await ensureMigrationsTableReady(driver);

    if (batchNos == null) {
      final lastBatchNumber = await getLastBatchNumber(driver, Migrator.tableName);
      batchNos = lastBatchNumber + 1;
    }

    await _runMigration(migration, batchNos);
  }

  print('\n------- Completed DB migration 🚀  ------\n');
}

Future _runMigration(MigrationTask migration, int batchNos) async {
  final driver = migration.driver;
  final fileName = migration.name;

  for (final schema in migration.schemas) {
    if (await hasAlreadyMigratedScript(fileName, driver)) {
      print('𐄂 skipped: $fileName     reason: already been migrated');
      continue;
    }

    await driver.transaction((transactor) async {
      final serialized = schema.toScript(driver.blueprint);
      transactor.execute(serialized);
      transactor.insert(Migrator.tableName, {'migration': fileName, 'batch': batchNos});

      await transactor.commit();
    });

    print('✔ done $fileName');
  }
}

Future<void> doResetMigrationAction(Iterable<MigrationTask> allTasks) async {
  print('------- Resetting migrations  📦 -------\n');

  final allMigrationsFiles = List<MigrationTask>.from(allTasks);

  while (allMigrationsFiles.isNotEmpty) {
    final migration = allMigrationsFiles.removeLast();
    final driver = migration.driver;
    await ensureMigrationsTableReady(driver);

    final _ = await Query.query(Migrator.tableName, driver).orderByDesc('batch').all();
    if (_.isEmpty) {
      print('𐄂 skipped: ${migration.name}     reason: no migrations to rollback');
      continue;
    }

    final rollbacks = _.map((e) => _MigrationDbData.from(e)).map((e) {
      final found = allTasks.firstWhereOrNull((m) => m.name == e.migration);
      if (found == null) return null;
      return (batch: e.batch, migration: found);
    }).whereNotNull();

    if (rollbacks.isEmpty) continue;

    allMigrationsFiles.removeWhere((e) => rollbacks.any((m) => m.migration.name == e.name));

    await Future.wait(rollbacks.map((e) => _rollBackMigration(e.migration, e.batch)));
  }

  print('\n------- Reset migrations done 🚀 -------\n');
}

Future _rollBackMigration(MigrationTask migration, int batchNos) async {
  final driver = migration.driver;
  final fileName = migration.name;

  await driver.transaction((transactor) async {
    for (final schema in migration.schemas) {
      final schemaSql = schema.toScript(driver.blueprint);
      transactor.execute(schemaSql);

      final deleteSql = DeleteQuery(
        Migrator.tableName,
        driver,
        whereClause: Query.query(Migrator.tableName, driver).where('migration', '=', fileName),
      ).statement;
      transactor.execute(deleteSql);
    }

    await transactor.commit();
  });

  print('✔ done $fileName');
}
