import 'dart:io';
import 'package:yaroorm/src/builder/utils.dart';
import 'package:yaroorm/src/cli/commands/init_orm_command.dart';
import 'package:yaroorm/src/cli/commands/migrate_command.dart';
import 'package:yaroorm/src/cli/commands/migrate_fresh_command.dart';
import 'package:yaroorm/src/cli/commands/migrate_reset_command.dart';
import 'package:yaroorm/src/cli/commands/migrate_rollback_command.dart';
import 'package:yaroorm/src/cli/orm.dart';

const _commandsToRunInProxyClient = [
  MigrateCommand.commandName,
  MigrateFreshCommand.commandName,
  MigrationRollbackCommand.commandName,
  MigrationResetCommand.commandName,
];

void main(List<String> args) async {
  final isACommandForProxy = args.isNotEmpty && _commandsToRunInProxyClient.contains(args[0]);
  if (!isACommandForProxy) return OrmCLIRunner.start(args);

  await ensureMigratorFile();

  late Process process;

  if (kernelFile.existsSync()) {
    process = await Process.start('dart', ['run', kernelFile.path, ...args]);
  } else {
    process = await Process.start('dart', ['run', migratorFile, ...args]);
  }

  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);

  final exitCode = await process.exitCode;

  await syncProxyMigratorIfNecessary();

  exit(exitCode);
}
