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
  final workingDir = Directory.current;
  OrmCLIRunner.resolvedProjectCache = await resolveMigrationAndEntitiesInDir(workingDir);

  final isACommandForProxy = args.isNotEmpty && _commandsToRunInProxyClient.contains(args[0]);
  if (!isACommandForProxy) return OrmCLIRunner.start(args);

  final (_, makeSnapshot) = await (
    ensureMigratorFile(),
    invalidateKernelSnapshotIfNecessary(),
  ).wait;

  late Process process;

  if (kernelFile.existsSync()) {
    process = await Process.start('dart', ['run', kernelFile.path, ...args]);
  } else {
    final tasks = <Future<void> Function()>[
      () async => process = await Process.start('dart', ['run', migratorFile, ...args]),
      if (makeSnapshot) () => Process.run('dart', ['compile', 'kernel', migratorFile, '-o', kernelFile.path]),
    ];

    await tasks.map((e) => e.call()).wait;
  }

  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);

  final exitCode = await process.exitCode;

  exit(exitCode);
}
