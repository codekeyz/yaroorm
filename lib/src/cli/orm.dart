import 'package:cli_completion/cli_completion.dart';

import 'commands/command.dart';
import 'commands/migrate_command.dart';
import 'commands/migrate_fresh_command.dart';
import 'commands/migrate_reset_command.dart';
import 'commands/migrate_rollback_command.dart';

import '../config.dart';
import '../database/database.dart';

import '_misc.dart';
import 'logger.dart';

const executableName = 'yaroo orm';
const packageName = 'yaroo_cli';
const description = 'yaroorm command-line tool';

class OrmCLIRunner extends CompletionCommandRunner<int> {
  static Future<void> start(List<String> args, YaroormConfig config) async {
    return flushThenExit(await OrmCLIRunner._(config).run(args) ?? 0);
  }

  OrmCLIRunner._(YaroormConfig config) : super(executableName, description) {
    argParser.addOption(
      OrmCommand.connectionArg,
      abbr: 'c',
      help: 'specify database connection',
    );

    DB.init(config);

    addCommand(MigrateCommand());
    addCommand(MigrateFreshCommand());
    addCommand(MigrationRollbackCommand());
    addCommand(MigrationResetCommand());
  }

  @override
  void printUsage() => logger.info(usage);
}
