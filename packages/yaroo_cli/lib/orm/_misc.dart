import 'package:yaroo_cli/src/migration.dart';
import 'package:yaroorm/yaroorm.dart';

Future<void> ensureMigrationsTableReady(DatabaseDriver driver) async {
  final hasTable = await driver.hasTable(DB.config.migrationsTable);
  if (hasTable) return;

  final script = MigrationDataSchema.toScript(driver.blueprint);
  await driver.execute(script);
}

Future<bool> hasAlreadyMigratedScript(
  String scriptName,
  DatabaseDriver driver,
) async {
  final result = await MigrationQuery.driver(driver).equal('migration', scriptName).findOne();
  return result != null;
}

Future<int> getLastBatchNumber(
  DatabaseDriver driver,
  String migrationsTable,
) async {
  return (await MigrationQuery.driver(driver).max('batch')).toInt();
}
