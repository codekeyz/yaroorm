import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaroorm/src/cli/commands/init_orm_command.dart';
import 'package:yaroorm/src/cli/orm.dart';

const _migratorFileContent = '''
import 'package:yaroorm/src/cli/orm.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../database/database.dart';

void main(List<String> args) async {
  initializeORM();

  await OrmCLIRunner.start(args);
}
''';

void main(List<String> args) async {
  final migratorDirectoryPath = path.join(Directory.current.path, '.dart_tool', 'yaroorm');
  final dir = Directory(migratorDirectoryPath);
  if (!dir.existsSync()) dir.createSync();

  final dartFile = path.join(migratorDirectoryPath, 'migrator.dart');
  final kernelFilePath = path.join(migratorDirectoryPath, 'migrator_kernel');

  final migratorFile = File(dartFile);
  final kernelFile = File(kernelFilePath);

  if (!migratorFile.existsSync()) {
    migratorFile.writeAsStringSync(_migratorFileContent);
  }

  final isInitCommand = args.isNotEmpty && args[0] == InitializeOrmCommand.commandName;
  if (isInitCommand) {
    if (kernelFile.existsSync()) kernelFile.delete();
    return OrmCLIRunner.start(args);
  }

  late Process process;

  if (kernelFile.existsSync()) {
    process = await Process.start('dart', ['run', kernelFilePath, ...args]);
  } else {
    process = await Process.start('dart', ['run', dartFile, ...args]);
  }

  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);

  if (!isInitCommand && !kernelFile.existsSync()) {
    /// TODO(codekeyz): add checksum check for invalidating kernel snapshot
    Process.start('dart', ['compile', 'kernel', dartFile, '-o', kernelFilePath], mode: ProcessStartMode.detached);
  }
}
