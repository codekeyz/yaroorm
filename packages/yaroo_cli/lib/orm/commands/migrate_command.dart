import 'dart:async';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../src/logger.dart';
import '../_misc.dart';
import '../orm.dart';
import 'command.dart';

class MigrateCommand extends OrmCommand {
  @override
  String get description => 'migrate your database';

  @override
  String get name => 'migrate';

  @override
  Future<void> execute(DatabaseDriver driver) async {
    await ensureMigrationsTableReady(driver);

    final lastBatchNumber =
        await getLastBatchNumber(driver, migrationTableName);
    final batchNos = lastBatchNumber + 1;

    logger.info(backgroundBlack
        .wrap('               Starting DB migration  📦                \n'));

    for (final migration in migrationDefinitions) {
      final fileName = migration.name;

      if (await hasAlreadyMigratedScript(fileName, driver)) {
        print('𐄂 skipped: $fileName     reason: already migrated');
        continue;
      }

      await driver.transaction((txnDriver) async {
        for (final schema in migration.up) {
          final sql = schema.toScript(driver.blueprint);
          await txnDriver.execute(sql);
        }

        await Query.table(migrationTableName)
            .driver(txnDriver)
            .insert(MigrationData(fileName, batchNos).to_db_data);

        print('✔ done:   $fileName');
      });
    }

    logger.info(backgroundBlack
        .wrap('\n               Completed DB migration 🚀                \n'));
  }
}
