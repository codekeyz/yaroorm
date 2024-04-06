import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:grammer/grammer.dart';
import 'package:collection/collection.dart';

const yaroormIdentifier = 'package:yaroorm/src/database/entity/entity.dart';

class EntityAnalyzer {
  final AnalysisContextCollection collection;

  EntityAnalyzer(Directory projectDir)
      : collection = AnalysisContextCollection(
          includedPaths: [
            path.join(projectDir.path, 'lib/src/models'),
            path.join(projectDir.path, 'test/models'),
          ],
          resourceProvider: PhysicalResourceProvider.INSTANCE,
        );

  Future<void> analyze() async {
    await for (var (library, filePath, _) in _libraries) {
      final libraryElement = library.element;
      final topElements = libraryElement.topLevelElements;
      final classElements = topElements.whereType<ClassElement>().where(
          (e) => e.supertype?.element.library.identifier == yaroormIdentifier);
      if (classElements.isEmpty) return;

      analyzeClassElement(libraryElement, filePath, classElements.first);
    }
  }

  void analyzeClassElement(
    LibraryElement libElement,
    String filePath,
    ClassElement classElement,
  ) async {
    final fields = classElement.fields.where(allowedTypes).toList();

    final className = classElement.name;

    final tableMeta = classElement.metadata
        .firstWhereOrNull(
            (e) => e.element?.library?.identifier == yaroormIdentifier)
        ?.computeConstantValue();
    final tableName = tableMeta?.getField('name')?.toStringValue() ??
        className.snakeCase.toPlural().first;

    final primaryKey = getEntityField(fields, 'PrimaryKey');
    final createdAtField = getEntityField(fields, 'CreatedAtColumn')?.field;
    final updatedAtField = getEntityField(fields, 'UpdatedAtColumn')?.field;
    final converters = tableMeta?.getField('converters')!.toListValue();

    if (primaryKey == null) {
      throw Exception("$className Entity doesn't have primary key");
    }

    final autoIncrementPrimaryKey =
        primaryKey.meta.getField('autoIncrement')!.toBoolValue()!;
    final timestampsEnabled = (createdAtField ?? updatedAtField) != null;

    /// other properties aside primarykey, updatedAt and createdAt
    final normalFields = fields.where(
        (e) => ![createdAtField, updatedAtField, primaryKey.field].contains(e));

    final creatableFields = [
      if (!autoIncrementPrimaryKey) primaryKey.field,
      ...normalFields
    ];

    final primaryConstructor =
        classElement.constructors.firstWhereOrNull((e) => e.name == "");
    if (primaryConstructor == null) {
      throw '$className Entity does not have a default constructor';
    }

    final fieldNames = fields.map((e) => e.name);
    final notAllowedProps =
        primaryConstructor.children.where((e) => !fieldNames.contains(e.name));
    if (notAllowedProps.isNotEmpty) {
      throw Exception(
          'These props are not allowed in $className Entity default constructor: ${notAllowedProps.join(', ')}');
    }

    bool isNullable(DartType type) {
      return libElement.typeSystem.isNullable(type);
    }

    String fieldToString(FieldElement e) {
      final symbol = '#${e.name}';

      final requiredOpts = '''
              "${e.name}",
               ${e.type.getDisplayString(withNullability: false)}, 
               $symbol
            ''';

      if (e == primaryKey.field) {
        return '''PrimaryKeyField(
          $requiredOpts)
          ${!autoIncrementPrimaryKey ? ', autoIncrement: false' : ''}''';
      }

      return '''DBEntityField(
        $requiredOpts 
        ${isNullable(e.type) ? ', nullable: true' : ''})'''
          .trim();
    }

    final typeDataName = '${className.snakeCase}TypeData';
    final queryName = '${className}Query';

    final library = Library((b) => b
      ..comments.add('ignore_for_file: non_constant_identifier_names')
      ..body.addAll([
        Directive.partOf(path.basename(filePath)),
        Method((m) => m
          ..name = queryName
          ..returns = refer('Query<$className>')
          ..type = MethodType.getter
          ..lambda = true
          ..body = Code('DB.query<$className>()')),
        Method((m) => m
          ..name = '${classElement.name.pascalCase}Schema'
          ..returns = refer('CreateSchema')
          ..lambda = true
          ..type = MethodType.getter
          ..body = Code('Schema.fromEntity<$className>()')),
        Method((m) => m
          ..name = typeDataName
          ..returns = refer('DBEntity<$className>')
          ..type = MethodType.getter
          ..lambda = true
          ..body = Code(
            '''DBEntity<$className>(
                "$tableName", 
                timestampsEnabled: $timestampsEnabled, 
                columns: ${fields.map(fieldToString).toList()},
                mirror: _\$${className}EntityMirror.new,
                build: (args) => ${_generateConstructorCode(className, primaryConstructor)},
                ${converters == null ? '' : 'converters: ${converters.map(processAnnotation).toList()},'})''',
          )),
        Class(
          (b) => b
            ..name = '_\$${className}EntityMirror'
            ..extend = refer('EntityMirror<$className>')
            ..constructors.add(Constructor(
              (b) => b
                ..constant = true
                ..requiredParameters.add(Parameter((p) => p
                  ..toSuper = true
                  ..name = 'instance')),
            ))
            ..methods.addAll([
              Method((m) => m
                ..name = 'get'
                ..annotations.add(CodeExpression(Code('override')))
                ..requiredParameters.add(Parameter((p) => p
                  ..name = 'field'
                  ..type = refer('Symbol')))
                ..returns = refer('Object?')
                ..body = Code('''
return switch(field) {
  ${fields.map((e) => '''
  #${e.name} => instance.${e.name}
''').join(',')},
  _ => throw Exception('Unknown property \$field'),
};
''')),
            ]),
        ),
        Extension((b) => b
          ..name = '${className}QueryExtension'
          ..on = refer('Query<$className>')
          ..methods.addAll([
            Method(
              (m) => m
                ..name = 'create'
                ..returns = refer('Future<$className>')
                ..modifier = MethodModifier.async
                ..optionalParameters.addAll(creatableFields.map(
                  (field) => Parameter((p) => p
                    ..name = field.name
                    ..named = true
                    ..type = refer('${field.type}')
                    ..required = !isNullable(field.type)),
                ))
                ..body = Code('''return $queryName.insert({
                ${creatableFields.map((e) => '#${e.name}: ${e.name}').join(',')}
                ,});'''),
            ),
            Method(
              (m) => m
                ..name = 'update'
                ..returns = refer('Future<void>')
                ..modifier = MethodModifier.async
                ..optionalParameters.addAll([
                  Parameter((p) => p
                    ..name = 'where'
                    ..named = true
                    ..type = refer('WhereBuilder<$className>')
                    ..required = true),
                  Parameter((p) => p
                    ..name = 'value'
                    ..named = true
                    ..type = refer(className)
                    ..required = true)
                ])
                ..body = Code('''
                final mirror = $typeDataName.mirror(value);
                final props = {
      for (final column in $typeDataName.columns) column.dartName: mirror.get(column.dartName),
    };  

     final update = UpdateQuery(
      entity.tableName,
      whereClause: where(this),
      data: conformToDbTypes(props, converters),
    );

     await $queryName.accept<UpdateQuery>(update);
'''),
            ),
          ]))
      ]));

    final actualFilePath =
        path.basename(filePath).replaceFirst('.dart', '.entity.dart');

    final df = path.join(path.dirname(filePath), actualFilePath);

    final result = DartFormatter().format('${library.accept(DartEmitter())}');
    File(df).writeAsStringSync(result);
  }

  Stream<(ResolvedLibraryResult, String, String)> get _libraries async* {
    for (var context in collection.contexts) {
      final analyzedDartFiles = context.contextRoot.analyzedFiles().where(
          (path) =>
              path.endsWith('.dart') &&
              !path.endsWith('_test.dart') &&
              !path.endsWith('.g.dart') &&
              !path.endsWith('.e.dart'));

      for (var filePath in analyzedDartFiles) {
        var library = await context.currentSession.getResolvedLibrary(filePath);
        if (library is ResolvedLibraryResult) {
          yield (library, filePath, context.contextRoot.root.path);
        }
      }
    }
  }
}

bool allowedTypes(FieldElement field) {
  return field.getter?.isSynthetic ?? false;
}

String _generateConstructorCode(
    String className, ConstructorElement constructor) {
  final sb = StringBuffer()..write('$className(');

  final normalParams = constructor.type.normalParameterNames;
  final namedParams = constructor.type.namedParameterTypes.keys;

  if (normalParams.isNotEmpty) {
    sb
      ..write(normalParams.map((name) => 'args[#$name]').join(','))
      ..write(',');
  }

  if (namedParams.isNotEmpty) {
    sb
      ..writeln(namedParams.map((name) => '$name: args[#$name]').join(', '))
      ..write(',');
  }

  return (sb..write(')')).toString();
}

/// Returns the field and it's meta value
({FieldElement field, DartObject meta})? getEntityField(
    List<FieldElement> fields, String type) {
  ElementAnnotation? metaData;

  final field = fields.firstWhereOrNull((f) {
    metaData = f.metadata.firstWhereOrNull((e) =>
        e.element?.library?.identifier == yaroormIdentifier &&
        (e.element is PropertyAccessorElement) &&
        (e.element as PropertyAccessorElement).returnType.toString() == type);

    return metaData != null;
  });
  if (field == null) return null;

  return (field: field, meta: metaData!.computeConstantValue()!);
}

/// Process entity annotation
String processAnnotation(DartObject constantValue) {
  final classElement = constantValue.type!.element as ClassElement;
  assert(classElement.supertype!.typeArguments.length == 2,
      'Should have two type arguments');

  final variable = constantValue.variable;
  if (variable != null) return variable.name;

  final custructor = classElement.constructors.first;
  if (custructor.parameters.isEmpty) {
    return '${classElement.name}()';
  }

  /// TODO(codekeyz): resolve constructor for TypeConverters
  throw UnsupportedError('Parameters for TypeConverters not yet supported');
}
