import 'dart:async';

import 'package:collection/collection.dart';
import 'package:yaroo_cli/src/migration.dart';
import 'package:yaroorm/yaroorm.dart';

import '../_misc.dart';
import 'command.dart';
import 'migrate_rollback_command.dart';

class MigrationResetCommand extends OrmCommand {
  @override
  String get description => 'reset database migrations';

  @override
  String get name => 'migrate:reset';

  @override
  Future<void> execute(DatabaseDriver driver) async {
    await ensureMigrationsTableReady(driver);

    final migrationsList =
        await MigrationQuery.driver(driver).orderByDesc('batch').all();
    if (migrationsList.isEmpty) {
      print('𐄂 skipped: reason:     no migrations to reset');
      return;
    }

    print('------- Resetting migrations  📦 -------\n');

    final rollbacks = migrationDefinitions.reversed.map((e) {
      final entry =
          migrationsList.firstWhereOrNull((entry) => e.name == entry.migration);
      return entry == null ? null : (entry: entry, schemas: e.down);
    }).whereNotNull();

    await processRollbacks(driver, rollbacks);

    print('\n------- Reset migrations done 🚀 -------\n');
  }
}
