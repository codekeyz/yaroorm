import 'package:yaroorm/yaroorm.dart';

import 'migrator.dart';

Future<void> ensureMigrationsTableReady(DatabaseDriver driver) async {
  final hasTable = await driver.hasTable(Migrator.tableName);
  if (hasTable) return;

  final script = Migrator.migrationsSchema.toScript(driver.blueprint);
  await driver.execute(script);
}

Future<bool> hasAlreadyMigratedScript(String scriptName, DatabaseDriver driver) async {
  final result = await Query.query(Migrator.tableName, driver).where('migration', '=', scriptName).findOne();
  return result != null;
}

Future<int> getLastBatchNumber(DatabaseDriver driver, String migrationsTable) async {
  /// TODO:(codekeyz) rewrite this with the ORM.
  final result = await driver.rawQuery('SELECT MAX(batch) as max_batch FROM $migrationsTable');
  return result.first['max_batch'] ?? 0;
}
