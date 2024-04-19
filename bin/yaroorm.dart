import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaroorm/src/cli/logger.dart';

void main(List<String> args) async {
  final migratorDirectoryPath = migratorPath;
  final dartFile = path.join(migratorDirectoryPath, 'migrator.dart');
  final aotFilePath = path.join(migratorDirectoryPath, 'migrator');

  if (!File(dartFile).existsSync()) {
    logger.err('🗙 Migrator file does not exist');
    exit(0);
  }

  final aotFile = File(aotFilePath);
  if (!aotFile.existsSync()) {
    /// TODO(codekeyz): add checksum check for invalidating aot
    Process.start('dart', ['compile', 'exe', dartFile, '-o', aotFilePath], mode: ProcessStartMode.detached);
  }

  late Process process;

  if (aotFile.existsSync()) {
    process = await Process.start(aotFilePath, args);
  } else {
    process = await Process.start('dart', ['run', dartFile, ...args]);
  }

  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
}

String get migratorPath {
  return path.join(Directory.current.path, '.dart_tool', 'yaroorm/bin');
}
