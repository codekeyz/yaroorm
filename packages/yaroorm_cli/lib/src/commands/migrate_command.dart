import 'dart:async';

import 'package:yaroorm/yaroorm.dart';

import '../misc/utils.dart';
import '../misc/migration.dart';
import 'command.dart';

class MigrateCommand extends OrmCommand {
  static const String commandName = 'migrate';

  @override
  String get description => 'migrate your database';

  @override
  String get name => commandName;

  @override
  Future<void> execute(DatabaseDriver driver, {bool writeLogs = true}) async {
    await ensureMigrationsTableReady(driver);

    final lastBatchNumber = await getLastBatchNumber(driver, migrationTableName);
    final batchNos = lastBatchNumber + 1;

    for (final migration in migrationDefinitions) {
      final fileName = migration.name;

      if (await hasAlreadyMigratedScript(fileName, driver)) {
        migrationLogTable.add([fileName, '〽️ already migrated']);
        continue;
      }

      await driver.transaction((txnDriver) async {
        for (final schema in migration.up) {
          final sql = schema.toScript(driver.blueprint);
          await txnDriver.execute(sql);
        }

        await MigrationEntityQuery.driver(txnDriver).insert(NewMigrationEntity(
          migration: fileName,
          batch: batchNos,
        ));

        migrationLogTable.add([fileName, '✅ migrated']);
      });
    }

    if (writeLogs) {
      logger.write(migrationLogTable.toString());
    }
  }
}
