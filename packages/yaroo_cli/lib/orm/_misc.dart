import 'package:yaroo_cli/src/migration.dart';
import 'package:yaroorm/yaroorm.dart';

// ignore: non_constant_identifier_names
Query<MigrationEntity> get MigrationQuery => DB.query<MigrationEntity>(DB.config.migrationsTable);

Future<void> ensureMigrationsTableReady(DatabaseDriver driver) async {
  final hasTable = await driver.hasTable(DB.config.migrationsTable);
  if (hasTable) return;

  final script = MigrationEntitySchema.toScript(driver.blueprint);
  await driver.execute(script);
}

Future<bool> hasAlreadyMigratedScript(
  String scriptName,
  DatabaseDriver driver,
) async {
  final result = await MigrationQuery.driver(driver).Migration(scriptName).findOne();
  return result != null;
}

Future<int> getLastBatchNumber(
  DatabaseDriver driver,
  String migrationsTable,
) async {
  final result = await MigrationQuery.driver(driver).max('batch');
  return result.toInt();
}
