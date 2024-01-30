import 'package:cli_completion/cli_completion.dart';
import 'package:yaroo_cli/src/utils.dart';
import 'package:yaroorm/yaroorm.dart';

import '../src/logger.dart';
import 'commands/command.dart';
import 'commands/migrate_command.dart';
import 'commands/migrate_reset_command.dart';
import 'commands/migrate_rollback_command.dart';

class MigrationData extends Entity<int, MigrationData> {
  final String migration;
  final int batch;

  MigrationData(this.migration, this.batch);
}

Future<int> getLastBatchNumber(
    DatabaseDriver driver, String migrationsTable) async {
  /// TODO:(codekeyz) rewrite this with the ORM.
  final result = await driver
      .rawQuery('SELECT MAX(batch) as max_batch FROM $migrationsTable');
  return result.first['max_batch'] ?? 0;
}

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
    addCommand(MigrationRollbackCommand());
    addCommand(MigrationResetCommand());
  }

  @override
  void printUsage() => logger.info(usage);
}
