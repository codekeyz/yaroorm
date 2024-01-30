import 'package:yaroorm/migration.dart';
import 'package:yaroorm/yaroorm.dart';

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
  String scriptName,
  DatabaseDriver driver,
) async {
  final result = await Query.table(DB.config.migrationsTable)
      .driver(driver)
      .whereEqual('migration', scriptName)
      .findOne();
  return result != null;
}
