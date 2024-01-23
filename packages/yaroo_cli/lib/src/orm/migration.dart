import 'package:args/command_runner.dart';

import './migrate_command.dart';
import './migrate_reset_command.dart';
import './migrate_rollback_command.dart';

class ORMCommand extends Command<int> {
  ORMCommand() {
    addSubcommand(MigrateCommand());
    addSubcommand(MigrationRollbackCommand());
    addSubcommand(MigrationResetCommand());
  }

  @override
  String get description => 'yaroorm migration command';

  @override
  String get name => 'orm';
}
