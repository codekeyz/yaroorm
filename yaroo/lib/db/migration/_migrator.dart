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

typedef Rollback = ({int batch, String name, MigrationTask? migration});

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

    final migrationInfoFromDB = await Query.query(Migrator.tableName).driver(driver).orderByDesc('batch').all();
    if (migrationInfoFromDB.isEmpty) {
      print('𐄂 skipped: reason:     no migrations to reset');
      return;
    }

    print('------- Resetting migrations  📦 -------\n');

    final Iterable<Rollback> rollbacks = migrationInfoFromDB.map((e) => _MigrationDbData.from(e)).map((e) {
      final found = allTasks.firstWhereOrNull((m) => m.name == e.migration);
      return (batch: e.batch, name: e.migration, migration: found);
    }).whereNotNull();

    await _processRollbacks(driver, rollbacks);

    print('\n------- Reset migrations done 🚀 -------\n');
  }

  static Future<void> rollBackMigration(DatabaseDriver driver, Iterable<MigrationTask> allTasks) async {
    final lastBatch = await Query.query(Migrator.tableName).driver(driver).orderByDesc('batch').get();
    if (lastBatch == null) {
      print('𐄂 skipped: reason:     no migration to rollback');
      return;
    }

    final migrationDbData = _MigrationDbData.from(lastBatch);
    final rollbacks = allTasks
        .where((e) => e.name == migrationDbData.migration)
        .map((e) => (name: e.name, migration: e, batch: migrationDbData.batch));

    print('------- Rolling back ${migrationDbData.migration}  📦 -------\n');

    await _processRollbacks(driver, rollbacks);

    print('\n------- Rollback done 🚀 -------\n');
  }

  static Future<void> _processRollbacks(DatabaseDriver driver, Iterable<Rollback> rollbacks) async {
    for (final rollback in rollbacks) {
      await driver.transaction((transactor) async {
        final schemas = rollback.migration?.schemas ?? [];
        if (schemas.isNotEmpty) {
          // ignore: avoid_function_literals_in_foreach_calls
          schemas.forEach((e) => transactor.execute(e.toScript(driver.blueprint)));
        }

        await Query.query(Migrator.tableName).driver(transactor).where('migration', '=', rollback.name).delete();

        await transactor.commit();
      });

      print('✔ rolled back: ${rollback.name}');
    }
  }
}
