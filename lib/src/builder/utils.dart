import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:grammer/grammer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'package:crypto/crypto.dart' show md5;
import 'package:yaroorm/src/cli/orm.dart';

import '../cli/commands/init_orm_command.dart';
import '../database/database.dart' show UseORMConfig;
import '../database/entity/entity.dart' as entity;
import '../migration.dart' show Migration;

class YaroormCliException implements Exception {
  final String message;
  YaroormCliException(this.message) : super();

  @override
  String toString() => 'ORM CLI Error: $message';
}

TypeChecker typeChecker(Type type) => TypeChecker.fromRuntime(type);

extension DartTypeExt on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;
}

String getFieldDbName(FieldElement element, {DartObject? meta}) {
  final elementName = element.name;
  meta ??= typeChecker(entity.TableColumn).firstAnnotationOf(element, throwOnUnresolved: false);
  if (meta != null) {
    return ConstantReader(meta).peek('name')?.stringValue ?? elementName;
  }
  return elementName;
}

String getTableName(ClassElement element) {
  final meta = typeChecker(entity.Table).firstAnnotationOf(element, throwOnUnresolved: false);
  return ConstantReader(meta).peek('name')?.stringValue ?? element.name.snakeCase.toPlural().first.toLowerCase();
}

String getTypeDefName(String className) {
  return '${className.pascalCase.toLowerCase()}TypeDef';
}

final RegExp _migrationTimestampRegex = RegExp(r'(\d{4})_(\d{2})_(\d{2})_(\d{6})');

DateTime parseMigrationFileDate(String fileName) {
  final match = _migrationTimestampRegex.firstMatch(fileName);
  if (match == null) {
    throw YaroormCliException('Invalid migration name: -> $fileName');
  }

  final year = match.group(1);
  final month = match.group(2);
  final day = match.group(3);
  final time = match.group(4);

  if (year == null || month == null || day == null || time == null) {
    throw YaroormCliException('Invalid migration name: -> $fileName');
  }

  return DateTime(
    int.parse(year),
    int.parse(month),
    int.parse(day),
    int.parse(time.substring(0, 2)),
    int.parse(time.substring(2, 4)),
    int.parse(time.substring(4)),
  );
}

String getMigrationFileName(String name, DateTime date) {
  String twoDigit(int number) => number.toString().padLeft(2, '0');
  return '${date.year}_${twoDigit(date.month)}_${twoDigit(date.day)}_${twoDigit(date.hour)}${twoDigit(date.minute)}${twoDigit(date.second)}_$name';
}

typedef ResolvedProject = ({
  List<Item> migrations,
  List<Item> entities,
  TopLevelVariableElement dbConfig,
});

Future<ResolvedProject> resolveMigrationAndEntitiesInDir(Directory workingDir) async {
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
        }

        dbConfig = config;
      } else {
        throw YaroormCliException('Found more than one ORM Config');
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
  for (final context in collection.contexts) {
    final analyzedFiles = context.contextRoot.analyzedFiles().toList();

    final futures =
        analyzedFiles.where((path) => path.endsWith('.dart') && !path.endsWith('_test.dart')).map((filePath) async {
      final library = await context.currentSession.getResolvedLibrary(filePath);
      if (library is! ResolvedLibraryResult) return null;
      return (library, filePath, context.contextRoot.root.path);
    });

    for (final result in await Future.wait(futures)) {
      if (result != null) {
        yield result;
      }
    }
  }
}

typedef FieldElementAndReader = ({FieldElement field, ConstantReader reader});

final class ParsedEntityClass {
  final ClassElement element;
  final ConstructorElement constructor;

  final String table;
  final String className;

  final List<FieldElement> allFields;

  /// {current_field_in_class : external entity being referenced and field}
  final Map<Symbol, ({ParsedEntityClass entity, Symbol field, ConstantReader reader})> bindings;

  final List<FieldElement> getters;

  /// All other properties aside primarykey, updatedAt and createdAt.
  final List<FieldElement> normalFields;

  final FieldElementAndReader primaryKey;
  final FieldElementAndReader? createdAtField, updatedAtField;

  List<FieldElement> get hasManyGetters =>
      getters.where((getter) => typeChecker(entity.HasMany).isExactlyType(getter.type)).toList();

  List<FieldElement> get belongsToGetters =>
      getters.where((getter) => typeChecker(entity.BelongsTo).isExactlyType(getter.type)).toList();

  List<FieldElement> get hasOneGetters =>
      getters.where((getter) => typeChecker(entity.HasOne).isExactlyType(getter.type)).toList();

  bool get hasAutoIncrementingPrimaryKey {
    return primaryKey.reader.peek('autoIncrement')!.boolValue;
  }

  bool get timestampsEnabled => (createdAtField ?? updatedAtField) != null;

  List<FieldElement> get fieldsRequiredForCreate => [
        if (!hasAutoIncrementingPrimaryKey) primaryKey.field,
        ...normalFields,
      ];

  const ParsedEntityClass(
    this.table,
    this.className,
    this.element, {
    required this.primaryKey,
    required this.constructor,
    required this.normalFields,
    this.bindings = const {},
    this.createdAtField,
    this.updatedAtField,
    required this.allFields,
    this.getters = const [],
  });

  factory ParsedEntityClass.parse(ClassElement element, {ConstantReader? reader}) {
    final className = element.name;
    final tableName = getTableName(element);
    final fields = element.fields.where(_allowedTypes).toList(growable: false);

    final primaryKey = _getFieldAnnotationByType(fields, entity.PrimaryKey);
    final createdAt = _getFieldAnnotationByType(fields, entity.CreatedAtColumn);
    final updatedAt = _getFieldAnnotationByType(fields, entity.UpdatedAtColumn);

    // Check should have primary key
    if (primaryKey == null) {
      throw Exception("${element.name} Entity doesn't have primary key");
    }

    // Validate un-named class constructor
    final primaryConstructor = element.constructors.firstWhereOrNull((e) => e.name == "");
    if (primaryConstructor == null) {
      throw InvalidGenerationSource(
        '$className Entity does not have a default constructor',
        element: element,
      );
    }

    final fieldNames = fields.map((e) => e.name);
    final notAllowedProps = primaryConstructor.children.where((e) => !fieldNames.contains(e.name));
    if (notAllowedProps.isNotEmpty) {
      throw InvalidGenerationSource(
        'These props are not allowed in $className Entity default constructor: ${notAllowedProps.join(', ')}',
        element: notAllowedProps.first,
      );
    }

    final normalFields = fields
        .where((e) => ![primaryKey.field, createdAt?.field, updatedAt?.field].contains(e))
        .toList(growable: false);

    final fieldsWithBindings = _getFieldsAndReaders(normalFields, entity.bindTo);

    final Map<Symbol, ({ParsedEntityClass entity, Symbol field, ConstantReader reader})> bindings = {};

    for (final field in fieldsWithBindings) {
      final relatedClass = field.reader.peek('type')!.typeValue.element as ClassElement;
      final parsedRelatedClass = ParsedEntityClass.parse(relatedClass);

      /// Check the field we're binding onto. If provided, validate that if exists
      /// if not, use the related class primary key
      final fieldToBind = field.reader.peek('on')?.symbolValue ?? Symbol(parsedRelatedClass.primaryKey.field.name);
      final referencedField = parsedRelatedClass.allFields.firstWhereOrNull((e) => Symbol(e.name) == fieldToBind);
      if (referencedField == null) {
        throw InvalidGenerationSource(
          'Field $fieldToBind used in Binding does not exist on ${parsedRelatedClass.className} Entity',
          element: field.field,
        );
      }

      if (referencedField.type != field.field.type) {
        throw InvalidGenerationSource(
          'Type-mismatch between fields $className.${field.field.name}(${field.field.type}) and ${parsedRelatedClass.className}.${referencedField.name}(${referencedField.type})',
          element: field.field,
        );
      }

      bindings[Symbol(field.field.name)] = (entity: parsedRelatedClass, field: fieldToBind, reader: field.reader);
    }

    return ParsedEntityClass(
      tableName,
      className,
      element,
      allFields: fields,
      bindings: bindings,
      normalFields: normalFields,
      getters: element.fields.where((e) => e.getter?.isSynthetic == false).toList(),
      primaryKey: primaryKey,
      constructor: primaryConstructor,
      createdAtField: createdAt,
      updatedAtField: updatedAt,
    );
  }

  static bool _allowedTypes(FieldElement field) {
    return field.getter?.isSynthetic ?? false;
  }

  static FieldElementAndReader? _getFieldAnnotationByType(List<FieldElement> fields, Type type) {
    for (final field in fields) {
      final result = typeChecker(type).firstAnnotationOf(field, throwOnUnresolved: false);
      if (result != null) {
        return (field: field, reader: ConstantReader(result));
      }
    }
    return null;
  }

  static Iterable<FieldElementAndReader> _getFieldsAndReaders(List<FieldElement> fields, Type type) sync* {
    for (final field in fields) {
      final result = typeChecker(type).firstAnnotationOf(field, throwOnUnresolved: false);
      if (result == null) continue;
      yield (field: field, reader: ConstantReader(result));
    }
  }
}

String symbolToString(Symbol symbol) {
  final symbolAsString = symbol.toString();
  return symbolAsString.substring(8, symbolAsString.length - 2);
}

const _migratorFileContent = '''
import 'package:yaroorm/src/cli/orm.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../database/database.dart';

void main(List<String> args) async {
  initializeORM();

  await OrmCLIRunner.start(args);
}
''';

Future<void> ensureMigratorFile() async {
  final dir = Directory(yaroormDirectory);
  if (!dir.existsSync()) dir.createSync();

  final file = File(migratorFile);
  if (!file.existsSync()) {
    await file.writeAsString(_migratorFileContent);
  }
}

Future<bool> invalidateKernelSnapshotIfNecessary() async {
  final entitiesMd5 = OrmCLIRunner.resolvedProjectCache.entities
      .map((e) => e.elements.map((clazz) => '${clazz.name}: ${_generateMD5ForClassElement(clazz)}'))
      .flattened
      .join('\n');

  if (migratorCheckSumFile.existsSync()) {
    final existingChecksum = await migratorCheckSumFile.readAsString();
    if (existingChecksum == entitiesMd5) return false;
  }

  await [
    kernelFile.delete().safeRun(),
    migratorCheckSumFile.writeAsString(entitiesMd5, mode: FileMode.write).safeRun(),
  ].wait;

  return true;
}

String _generateMD5ForClassElement(ClassElement classElement) {
  final classInfo = StringBuffer()..writeln('Class: ${classElement.name}');
  for (var field in classElement.fields) {
    classInfo.writeln('Field: ${field.type} ${field.name} ${field.type.isNullable}');
  }

  for (var method in classElement.methods) {
    classInfo.writeln('Method: ${method.name}');
  }

  for (var metadata in classElement.metadata) {
    classInfo.writeln('Metadata: ${metadata.toString()}');
  }

  return md5.convert(utf8.encode(classInfo.toString())).toString();
}

extension _SafeCall<T> on Future<T> {
  Future<T?> safeRun({Function(Object error)? onError}) async {
    try {
      return await this;
    } catch (_) {
      onError?.call(_);
    }
    return null;
  }
}
