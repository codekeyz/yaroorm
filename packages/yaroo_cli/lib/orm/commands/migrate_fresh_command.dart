import 'package:yaroorm/yaroorm.dart';

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
    final result = await MigrationResetCommand().run();
    if (result == 0) await MigrateCommand().run();
  }
}
