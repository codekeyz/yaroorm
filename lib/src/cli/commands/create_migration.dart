import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:yaroorm/src/cli/commands/init_orm_command.dart';
import 'package:yaroorm/src/cli/logger.dart';
import '../../builder/utils.dart';
import '../../database/driver/driver.dart';
import 'command.dart';

class CreateMigrationCommand extends OrmCommand {
  static const String commandName = 'create';

  @override
  String get description => 'create migration file';

  @override
  String get name => commandName;

  @override
  Future<void> execute(DatabaseDriver driver) async {
    final defaultConn = ormConfig.defaultConnName;
    final name = argResults!.arguments.last.snakeCase;
    final time = DateTime.now();
    final fileName = getMigrationFileName(name, time);
    final directory = Directory.current;
    final progress = logger.progress('Create migration ${green.wrap(fileName)}');

    final library = Library((library) => library.body.addAll([
          Directive.import('package:yaroorm/yaroorm.dart'),
          Class((c) => c
            ..name = name.pascalCase
            ..extend = refer('Migration')
            ..constructors.addAll([
              if (defaultConn != dbConnection)
                Constructor((c) => c
                  ..constant = true
                  ..lambda = true
                  ..initializers.add(Code('super(connection: "$dbConnection")')))
            ])
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

    final emitter = DartEmitter(orderDirectives: true, useNullSafetySyntax: true);
    file.writeAsStringSync(DartFormatter().format(library.accept(emitter).toString().split('\n').join('\n')));

    final result = await resolveMigrationAndEntitiesInDir(directory);
    if (result.migrations.isEmpty) {
      progress.fail('Failed to create migration file.');
      return;
    }

    await initOrmInProject(directory, result.migrations, result.entities, result.dbConfig);

    progress.complete('Migration file created ✅');
  }
}
