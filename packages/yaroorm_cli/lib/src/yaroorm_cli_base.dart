import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:args/command_runner.dart';

import 'builder/utils.dart';
import 'commands/command.dart';
import 'commands/create_migration.dart';
import 'commands/init_orm_command.dart';
import 'commands/migrate_command.dart';
import 'commands/migrate_fresh_command.dart';
import 'commands/migrate_reset_command.dart';
import 'commands/migrate_rollback_command.dart';
import 'misc/utils.dart';

const executableName = 'yaroorm';
const description = 'yaroorm command-line tool';

class OrmCLIRunner extends CompletionCommandRunner<int> {
  static late ResolvedProject resolvedProjectCache;

  static Future<void> start(List<String> args) async {
    run() async {
      try {
        return (await OrmCLIRunner._().run(args)) ?? 0;
      } on UsageException catch (error) {
        print(error.toString());
        return ExitCode.software.code;
      }
    }

    return flushThenExit(await run());
  }

  OrmCLIRunner._() : super(executableName, description) {
    argParser.addOption(
      OrmCommand.connectionArg,
      abbr: 'c',
      help: 'specify database connection',
    );

    addCommand(InitializeOrmCommand());
    addCommand(CreateMigrationCommand());

    addCommand(MigrateCommand());
    addCommand(MigrateFreshCommand());
    addCommand(MigrationRollbackCommand());
    addCommand(MigrationResetCommand());
  }

  @override
  void printUsage() => logger.info(usage);
}
