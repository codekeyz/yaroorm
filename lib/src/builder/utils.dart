import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

import '../database/database.dart' show UseORMConfig;
import '../database/entity/entity.dart' as entity;
import '../migration.dart' show Migration;

class YaroormCliException implements Exception {
  final String message;
  YaroormCliException(this.message) : super();

  @override
  String toString() {
    return 'ORM CLI Error: $message';
  }
}

typedef FieldData = ({FieldElement field, ConstantReader reader});

TypeChecker typeChecker(Type type) => TypeChecker.fromRuntime(type);

extension DartTypeExt on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;
}

String getFieldDbName(FieldElement element) {
  final elementName = element.name;
  final meta = typeChecker(entity.TableColumn).firstAnnotationOf(element, throwOnUnresolved: false);
  if (meta != null) {
    return ConstantReader(meta).peek('name')?.stringValue ?? elementName;
  }
  return elementName;
}

String getTypeDefName(String className) {
  return '${className.snakeCase}TypeData';
}

final _numberRegex = RegExp(r'\d+');
DateTime parseMigrationFileDate(String fileName) {
  final matches = _numberRegex.allMatches(fileName).map((e) => e.group(0)).toList();
  final time = matches.last;
  if (matches.isEmpty || matches.length != 4 || time!.length != 6) {
    throw YaroormCliException('Invalid migration name: -> $fileName');
  }
  return DateTime.parse(
      '${matches[0]}-${matches[1]}-${matches[2]} ${time.substring(0, 2)}:${time.substring(2, 4)}:${time.substring(4)}');
}

Future<
    ({
      List<Item> migrations,
      List<Item> entities,
      TopLevelVariableElement dbConfig,
    })> resolveMigrationAndEntitiesInDir(Directory workingDir) async {
  final collection = AnalysisContextCollection(
    includedPaths: [workingDir.absolute.path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  final List<Item> migrations = [];
  final List<Item> entities = [];

  TopLevelVariableElement? dbConfig;

  await for (final (library, _, _) in _libraries(collection)) {
    /// Resolve ORM config
    final configIsInitiallyNull = dbConfig == null;
    final config = library.element.topLevelElements
        .firstWhereOrNull((element) => typeChecker(UseORMConfig).hasAnnotationOfExact(element));
    if (config != null) {
      if (configIsInitiallyNull) {
        if (config is! TopLevelVariableElement || config.isPrivate) {
          throw YaroormCliException('ORM config has to be a top level public variable');
          // progress.fail('🗙 ORM initialize step failed');
          // logger.err();
          // exit(ExitCode.software.code);
        }

        dbConfig = config;
      } else {
        throw YaroormCliException('Found more than one ORM Config');

        // progress.fail('🗙 ORM initialize step failed');
        // logger.err('Found more than one ORM Config');
        // exit(ExitCode.software.code);
      }
    }

    final result = _validateLibrary(library, library.element.identifier);
    if (result == null) continue;

    if (result.migrations != null) {
      migrations.add(result.migrations!);
    }

    if (result.entityClasses != null) {
      entities.add(result.entityClasses!);
    }
  }

  if (dbConfig == null) {
    throw YaroormCliException('Did you forget to annotate ORM Config with ${cyan.wrap('@DB.useConfig')} ?');
  }

  return (migrations: migrations, entities: entities, dbConfig: dbConfig);
}

class Item {
  final Iterable<ClassElement> elements;
  final String path;

  const Item(this.elements, this.path);
}

({Item? migrations, Item? entityClasses})? _validateLibrary(ResolvedLibraryResult library, String identifier) {
  final classElements = library.element.topLevelElements
      .where((e) => !e.isPrivate && e is ClassElement && e.supertype != null && !e.isAbstract)
      .toList()
      .cast<ClassElement>();

  if (classElements.isEmpty) return null;

  final migrationClasses = classElements.where((element) => typeChecker(Migration).isExactlyType(element.supertype!));
  final entityClasses = classElements.where((element) => typeChecker(entity.Entity).isExactlyType(element.supertype!));

  return (
    migrations: migrationClasses.isEmpty ? null : Item(migrationClasses, identifier),
    entityClasses: entityClasses.isEmpty ? null : Item(entityClasses, identifier),
  );
}

Stream<(ResolvedLibraryResult, String, String)> _libraries(AnalysisContextCollection collection) async* {
  for (var context in collection.contexts) {
    final analyzedFiles = context.contextRoot.analyzedFiles().toList();
    final analyzedDartFiles = analyzedFiles.where((path) => path.endsWith('.dart') && !path.endsWith('_test.dart'));
    for (final filePath in analyzedDartFiles) {
      final library = await context.currentSession.getResolvedLibrary(filePath);
      if (library is ResolvedLibraryResult) {
        yield (library, filePath, context.contextRoot.root.path);
      }
    }
  }
}
