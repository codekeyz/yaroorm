import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../../yaroorm.dart';

import 'model/migration.dart';

final dartEmitter = DartEmitter(
  orderDirectives: true,
  useNullSafetySyntax: true,
);

final dartFormatter = DartFormatter();

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
  final result =
      await MigrationEntityQuery.driver(driver).findByMigration(scriptName);
  return result != null;
}

Future<int> getLastBatchNumber(
  DatabaseDriver driver,
  String migrationsTable,
) async {
  final result = await MigrationEntityQuery.driver(driver).max('batch');
  return result.toInt();
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}
