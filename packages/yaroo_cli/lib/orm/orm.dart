import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm/migration.dart';

class MigrationData extends Entity<int, MigrationData> {
  final String migration;
  final int batch;

  MigrationData(this.migration, this.batch);
}

final _migrationsSchema = Schema.create('migrations', ($table) {
  return $table
    ..id()
    ..string('migration')
    ..integer('batch');
});

Future<void> ensureMigrationsTableReady(DatabaseDriver driver) async {
  final hasTable = await driver.hasTable(DB.config.migrationsTable);
  if (hasTable) return;

  final script = _migrationsSchema.toScript(driver.blueprint);
  await driver.execute(script);
}

Future<bool> hasAlreadyMigratedScript(
    String scriptName, DatabaseDriver driver) async {
  final result = await Query.table(
    DB.config.migrationsTable,
  ).driver(driver).whereEqual('migration', scriptName).findOne();
  return result != null;
}

Future<int> getLastBatchNumber(
  DatabaseDriver driver,
  String migrationsTable,
) async {
  /// TODO:(codekeyz) rewrite this with the ORM.
  final result = await driver
      .rawQuery('SELECT MAX(batch) as max_batch FROM $migrationsTable');
  return result.first['max_batch'] ?? 0;
}
