import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:yaroorm/src/cli/_misc.dart';
import 'package:yaroorm/src/cli/commands/init_orm_command.dart';
import 'package:yaroorm/src/cli/logger.dart';
import '../../builder/utils.dart';

class CreateMigrationCommand extends Command<int> {
  static const String commandName = 'create';

  @override
  String get description => 'create migration file';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final name = argResults!.arguments.last.snakeCase;
    final time = DateTime.now();
    final fileName = getMigrationFileName(name, time);
    final directory = Directory.current;

    final progress =
        logger.progress('Create migration ${green.wrap(fileName)}');

    final library = Library((library) => library.body.addAll([
          Directive.import('package:yaroorm/yaroorm.dart'),
          Class((c) => c
            ..name = name.pascalCase
            ..extend = refer('Migration')
            ..methods.addAll([
              Method.returnsVoid((m) => m
                ..name = 'up'
                ..annotations.add(CodeExpression(Code('override')))
                ..body = const Code('')
                ..requiredParameters.add(Parameter((p) => p
                  ..name = 'schemas'
                  ..type = refer('List<Schema>')))),
              Method.returnsVoid((m) => m
                ..name = 'down'
                ..annotations.add(CodeExpression(Code('override')))
                ..body = const Code('')
                ..requiredParameters.add(Parameter((p) => p
                  ..name = 'schemas'
                  ..type = refer('List<Schema>'))))
            ])),
        ]));

    final file = File(path.join(migrationsDir.path, '$fileName.dart'));

    await file.writeAsString(dartFormatter
        .format(library.accept(dartEmitter).toString().split('\n').join('\n')));

    final result = await resolveMigrationAndEntitiesInDir(directory);
    if (result.migrations.isEmpty) {
      progress.fail('Failed to create migration file.');
      return ExitCode.software.code;
    }

    if (migratorCheckSumFile.existsSync()) migratorCheckSumFile.delete();
    if (kernelFile.existsSync()) kernelFile.delete();

    await initOrmInProject(
      directory,
      result.migrations,
      result.entities,
      result.dbConfig,
    );

    progress.complete('Migration file created ✅');

    return ExitCode.success.code;
  }
}
