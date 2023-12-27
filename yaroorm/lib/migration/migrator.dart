import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import 'cli.dart';
import 'utils.dart';

typedef Rollback = ({int batch, String name, MigrationTask? migration});

class MigrationData extends Entity<int> {
  final String migration;
  final int batch;

  MigrationData(this.migration, this.batch);

  static MigrationData fromJson(Map<String, dynamic> json) => MigrationData(
        json['migration'] as String,
        json['batch'] as int,
      )..id = PrimaryKey.thisFromJson(json['id']);

  @override
  Map<String, dynamic> toJson() => {'id': PrimaryKey.thisToJson(id), 'migration': migration, 'batch': batch};

  @override
  bool get enableTimestamps => false;
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
          await transactor.execute(serialized);
        }

        await Query.table<MigrationData>(Migrator.tableName)
            .driver(transactor)
            .insert(MigrationData(fileName, batchNos));

        print('✔ done:   $fileName');
      });
    }

    print('\n------- Completed DB migration 🚀  ------\n');
  }

  static Future<void> resetMigrations(DatabaseDriver driver, Iterable<MigrationTask> allTasks) async {
    await ensureMigrationsTableReady(driver);

    final migrationsList =
        await Query.table<MigrationData>(Migrator.tableName).driver(driver).orderByDesc('batch').all();
    if (migrationsList.isEmpty) {
      print('𐄂 skipped: reason:     no migrations to reset');
      return;
    }

    print('------- Resetting migrations  📦 -------\n');

    final rollbacks = migrationsList.map((e) {
      final found = allTasks.firstWhereOrNull((m) => m.name == e.migration);
      return found == null ? null : (batch: e.batch, name: e.migration, migration: found);
    }).whereNotNull();

    await _processRollbacks(driver, rollbacks);

    print('\n------- Reset migrations done 🚀 -------\n');
  }

  static Future<void> rollBackMigration(DatabaseDriver driver, Iterable<MigrationTask> allTasks) async {
    final migrationDbData =
        await Query.table<MigrationData>(Migrator.tableName).driver(driver).orderByDesc('batch').get();
    if (migrationDbData == null) {
      print('𐄂 skipped: reason:     no migration to rollback');
      return;
    }

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
          for (var e in schemas) {
            await transactor.execute(e.toScript(driver.blueprint));
          }
        }

        await Query.table(Migrator.tableName)
            .driver(transactor)
            .delete((where) => where.whereEqual('migration', rollback.name))
            .exec();
      });

      print('✔ rolled back: ${rollback.name}');
    }
  }
}
