import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';

import '_migrator.dart';
import 'cli.dart';

Future<void> ensureMigrationsTableReady(DatabaseDriver driver) async {
  final hasTable = await driver.hasTable(Migrator.tableName);
  if (hasTable) return;

  final script = MigratorCLI.migrationsSchema.toScript(driver.blueprint);
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

String? getValueFromCLIArs(String key, List<String> args) {
  final argument = args.firstWhereOrNull((arg) => arg.split('=').first == '--$key');
  if (argument == null) return null;
  return argument.split('=').last;
}
