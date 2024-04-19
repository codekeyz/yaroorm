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
    await MigrationResetCommand().execute(driver);
    await MigrateCommand().execute(driver);
  }
}
