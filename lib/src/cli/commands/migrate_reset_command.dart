import 'dart:async';

import 'package:collection/collection.dart';
import 'package:yaroorm/src/cli/logger.dart';
import '../../../yaroorm.dart';

import '../_misc.dart';
import '../model/migration.dart';
import 'command.dart';
import 'migrate_rollback_command.dart';

class MigrationResetCommand extends OrmCommand {
  @override
  String get description => 'reset database migrations';

  @override
  String get name => 'migrate:reset';

  @override
  Future<void> execute(DatabaseDriver driver, {bool writeLogs = true}) async {
    await ensureMigrationsTableReady(driver);

    final migrationsList = await MigrationEntityQuery.driver(driver).findMany(
      orderBy: [
        OrderMigrationEntityBy.batch(OrderDirection.desc),
      ],
    );
    if (migrationsList.isEmpty) {
      print('𐄂 skipped: reason:     no migrations to reset');
      return;
    }

    final rollbacks = migrationDefinitions.reversed.map((e) {
      final entry = migrationsList.firstWhereOrNull((entry) => e.name == entry.migration);
      return entry == null ? null : (entry: entry, schemas: e.down);
    }).whereNotNull();

    await processRollbacks(driver, rollbacks, table: migrationLogTable);

    if (writeLogs) {
      logger.write(migrationLogTable.toString());
    }
  }
}
