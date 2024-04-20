import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';
import 'package:yaroorm/src/cli/logger.dart';

import 'package:yaroorm/src/migration.dart' show Migration;
import 'package:yaroorm/src/database/entity/entity.dart' show Entity;

void main(List<String> args) async {
  final migratorDirectoryPath = migratorPath;
  final dartFile = path.join(migratorDirectoryPath, 'migrator.dart');
  final aotFilePath = path.join(migratorDirectoryPath, 'migrator');

  if (args.isNotEmpty && args[0] == 'init') {
    await _initOrmInProject(Directory.current);
    exit(0);
  }

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

Future<void> _initOrmInProject(Directory workingDir) async {
  // final progress = logger.progress('Initializing ORM in project');

  final collection = AnalysisContextCollection(
    includedPaths: [workingDir.absolute.path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  List<Item> migrations = [];
  List<Item> entities = [];

  await for (final (library, _, _) in _libraries(collection)) {
    final result = _validateLibrary(library, library.element.identifier);
    if (result == null) continue;

    if (result.migrations != null) {
      migrations.add(result.migrations!);
    }

    if (result.entityClasses != null) {
      entities.add(result.entityClasses!);
    }
  }

  print(migrations.map((e) => (e.elements.map((e) => e.name), e.path)));
  print(entities.map((e) => (e.elements.map((e) => e.name), e.path)));
}

TypeChecker _typeChecker(Type type) => TypeChecker.fromRuntime(type);

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

  final migrationClasses = classElements.where((element) => _typeChecker(Migration).isExactlyType(element.supertype!));
  final entityClasses = classElements.where((element) => _typeChecker(Entity).isExactlyType(element.supertype!));

  return (
    migrations: migrationClasses.isEmpty ? null : Item(migrationClasses, identifier),
    entityClasses: entityClasses.isEmpty ? null : Item(entityClasses, identifier),
  );
}

Stream<(ResolvedLibraryResult, String, String)> _libraries(AnalysisContextCollection collection) async* {
  for (var context in collection.contexts) {
    var analyzedFiles = context.contextRoot.analyzedFiles().toList();
    analyzedFiles.sort();
    final analyzedDartFiles = analyzedFiles.where((path) => path.endsWith('.dart') && !path.endsWith('_test.dart'));
    for (final filePath in analyzedDartFiles) {
      final library = await context.currentSession.getResolvedLibrary(filePath);
      if (library is ResolvedLibraryResult) {
        yield (library, filePath, context.contextRoot.root.path);
      }
    }
  }
}
