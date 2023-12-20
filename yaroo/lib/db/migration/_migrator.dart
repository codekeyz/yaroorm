import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import '_utils.dart';
import 'cli.dart';

class _MigrationDbData {
  final int id;
  final String migration;
  final int batch;

  const _MigrationDbData(this.id, this.migration, this.batch);

  static _MigrationDbData from(Map<String, dynamic> data) {
    return _MigrationDbData(data['id'], data['migration'], data['batch']);
  }
}

class Migrator {
  /// config keys for migrations
  static const migrationsTableNameKeyInConfig = 'migrationsTableName';
  static const migrationsKeyInConfig = 'migrations';

  static String tableName = 'migrations';

  static Future<void> runMigrations(DatabaseDriver driver, Iterable<MigrationTask> migrations) async {
    await ensureMigrationsTableReady(driver);

    final lastBatchNumber = await getLastBatchNumber(driver, Migrator.tableName);
    final batchNos = lastBatchNumber + 1;

    print('------- Starting DB migration  📦 -------\n');

    for (final migration in migrations) {
      final fileName = migration.name;

      if (await hasAlreadyMigratedScript(fileName, driver)) {
        print('𐄂 skipped: $fileName     reason: already migrated');
        continue;
      }

      await driver.transaction((transactor) async {
        for (final schema in migration.schemas) {
          final serialized = schema.toScript(driver.blueprint);
          transactor.execute(serialized);
        }

        transactor.insert(Migrator.tableName, {'migration': fileName, 'batch': batchNos});

        await transactor.commit();

        print('✔ done:   $fileName');
      });
    }

    print('\n------- Completed DB migration 🚀  ------\n');
  }

  static Future<void> resetMigrations(DatabaseDriver driver, Iterable<MigrationTask> allTasks) async {
    await ensureMigrationsTableReady(driver);

    print('------- Resetting migrations  📦 -------\n');

    final migrationInfoFromDB = await Query.query(Migrator.tableName, driver).orderByDesc('batch').all();
    if (migrationInfoFromDB.isNotEmpty) {
      final rollbacks = migrationInfoFromDB.map((e) => _MigrationDbData.from(e)).map((e) {
        final found = allTasks.firstWhereOrNull((m) => m.name == e.migration);
        return (batch: e.batch, name: e.migration, migration: found);
      }).whereNotNull();

      for (final rollback in rollbacks) {
        await driver.transaction((transactor) async {
          final schemas = rollback.migration?.schemas ?? [];
          if (schemas.isNotEmpty) {
            schemas.forEach((e) => transactor.execute(e.toScript(driver.blueprint)));
          }

          final deleteSql = DeleteQuery(
            Migrator.tableName,
            driver,
            whereClause: Query.query(Migrator.tableName, driver).where('migration', '=', rollback.name),
          ).statement;
          transactor.execute(deleteSql);

          await transactor.commit();
        });

        print('✔ rolled back: ${rollback.name}');
      }
    } else {
      print('𐄂 skipped: reason:     no migrations to rollback');
    }

    print('\n------- Reset migrations done 🚀 -------\n');
  }
}
