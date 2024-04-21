import 'package:yaroorm/src/cli/logger.dart';

import '../../../yaroorm.dart';

import 'command.dart';
import 'migrate_command.dart';
import 'migrate_reset_command.dart';

class MigrateFreshCommand extends OrmCommand {
  @override
  String get name => 'migrate:fresh';

  @override
  String get description => 'reset and re-run all database migrations';

  @override
  Future<void> execute(DatabaseDriver driver) async {
    await MigrationResetCommand().execute(driver, writeLogs: false);
    await MigrateCommand().execute(driver, writeLogs: false);
    logger.write(migrationLogTable.toString());
  }
}
