import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

// ignore: implementation_imports
import '../database/entity/entity.dart' as entity;
import 'utils.dart';

final _emitter = DartEmitter(useNullSafetySyntax: true, orderDirectives: true);

Builder generatorFactoryBuilder(BuilderOptions options) => SharedPartBuilder([EntityGenerator()], 'yaroorm');

class EntityGenerator extends GeneratorForAnnotation<entity.Table> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      final name = element.displayName;
      throw InvalidGenerationSourceError(
        'Generator cannot target `$name`.',
        todo: 'Remove the [Table] annotation from `$name`.',
        element: element,
      );
    }

    return _implementClass(element, annotation);
  }

  String _implementClass(ClassElement classElement, ConstantReader annotation) {
    final parsedEntity = ParsedEntityClass.parse(classElement);
    final className = classElement.name;

    final primaryKey = parsedEntity.primaryKey;
    final fields = parsedEntity.allFields;
    final createdAtField = parsedEntity.createdAtField?.field;
    final updatedAtField = parsedEntity.updatedAtField?.field;

    if (primaryKey == null) {
      throw Exception("$className Entity doesn't have primary key");
    }

    /// Validate class constructor
    final primaryConstructor = classElement.constructors.firstWhereOrNull((e) => e.name == "");
    if (primaryConstructor == null) {
      throw '$className Entity does not have a default constructor';
    }

    final fieldNames = fields.map((e) => e.name);
    final notAllowedProps = primaryConstructor.children.where((e) => !fieldNames.contains(e.name));
    if (notAllowedProps.isNotEmpty) {
      throw Exception(
          'These props are not allowed in $className Entity default constructor: ${notAllowedProps.join(', ')}');
    }

    final normalFields = parsedEntity.normalFields;

    final tableName = annotation.peek('name')!.stringValue;
    final converters = annotation.peek('converters')!.listValue;

    final autoIncrementPrimaryKey = primaryKey.reader.peek('autoIncrement')!.boolValue;
    final timestampsEnabled = (createdAtField ?? updatedAtField) != null;
    final creatableFields = parsedEntity.fieldsRequiredForCreate;

    String generateCodeForField(FieldElement e) {
      final symbol = '#${e.name}';
      final columnName = getFieldDbName(e);

      final meta = typeChecker(entity.TableColumn).firstAnnotationOf(e, throwOnUnresolved: false);

      final requiredOpts = '''
              "$columnName",
               ${e.type.getDisplayString(withNullability: false)},
               $symbol
            ''';

      if (meta != null) {
        final metaReader = ConstantReader(meta);
        final isReferenceField = typeChecker(entity.reference).isExactly(meta.type!.element!);

        if (isReferenceField) {
          final referencedType = metaReader.peek('type')!.typeValue;
          final element = referencedType.element as ClassElement;
          final superType = element.supertype?.element;

          if (superType == null || !typeChecker(entity.Entity).isExactly(superType)) {
            throw InvalidGenerationSourceError(
              'Generator cannot target field `${e.name}` on `$className` class.',
              element: element,
              todo: 'Type passed to [reference] annotation must be a subtype of `Entity`.',
            );
          }

          final onUpdate = metaReader.peek('onUpdate')?.objectValue.variable!.name;
          final onDelete = metaReader.peek('onDelete')?.objectValue.variable!.name;

          return '''DBEntityField.referenced<${element.name}>(
                  "$columnName", $symbol
                  ${onUpdate == null ? '' : ', onUpdate: ForeignKeyAction.$onUpdate'}
                  ${onDelete == null ? '' : ', onDelete: ForeignKeyAction.$onDelete'}
                  ,)''';
        }
      }

      if (e == createdAtField) {
        return '''DBEntityField.createdAt("$columnName", $symbol)''';
      }

      if (e == updatedAtField) {
        return '''DBEntityField.updatedAt("$columnName", $symbol)''';
      }

      if (e == primaryKey.field) {
        return '''DBEntityField.primaryKey(
          $requiredOpts
          ${autoIncrementPrimaryKey ? ', autoIncrement: true' : ''}
          )''';
      }

      return '''DBEntityField(
        $requiredOpts
        ${e.type.isNullable ? ', nullable: true' : ''})''';
    }

    final queryName = '${className}Query';
    final typeDataName = getTypeDefName(className);

    final library = Library((b) => b
      ..body.addAll([
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
                columns: ${fields.map(generateCodeForField).toList()},
                mirror: _\$${className}EntityMirror.new,
                build: (args) => ${_generateConstructorCode(className, primaryConstructor)},
                ${converters.isEmpty ? '' : 'converters: ${converters.map(processAnnotation).toList()},'})''',
          )),

        /// Generate Entity Mirror for Reflection
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
              Method(
                (m) => m
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
'''),
              ),
            ]),
        ),

        /// Generate Typed OrderBy's
        Class((b) => b
          ..name = 'Order${className}By'
          ..extend = refer('OrderBy<$className>')
          ..constructors.addAll([
            ...normalFields,
            if (createdAtField != null) createdAtField,
            if (updatedAtField != null) updatedAtField,
          ].map((field) => Constructor((c) => c
            ..name = field.name
            ..constant = true
            ..lambda = true
            ..initializers.add(Code('super("${getFieldDbName(field)}", direction)'))
            ..requiredParameters.add(Parameter((p) => p
              ..type = refer('OrderDirection')
              ..name = 'direction')))))),

        /// Generate Entity Create Extension
        Extension(
          (b) => b
            ..name = '${className}QueryExtension'
            ..on = refer('Query<$className>')
            ..methods.addAll([
              _generateGetByPropertyMethod(primaryKey.field, className),
              ...normalFields.map((e) => _generateGetByPropertyMethod(e, className)),
              Method(
                (m) => m
                  ..name = 'create'
                  ..returns = refer('Future<$className>')
                  ..optionalParameters.addAll(creatableFields.map(
                    (field) => Parameter((p) => p
                      ..name = field.name
                      ..named = true
                      ..type = refer('${field.type}')
                      ..required = !field.type.isNullable),
                  ))
                  ..body = Code('''return \$insert({
                ${creatableFields.map((e) => '#${e.name}: ${e.name}').join(',')}
                });'''),
              ),
            ]),
        ),

        /// Generate Typed Entity WhereBuilder Extension
        Extension((b) => b
          ..name = '${className}WhereBuilderExtension'
          ..on = refer('WhereClauseBuilder<$className>')
          ..methods.addAll([
            _generateFieldWhereClause(primaryKey.field, className),
            ...normalFields.map((e) => _generateFieldWhereClause(e, className)),
          ])),

        /// Generate Typed Entity Update Extension
        Extension((b) => b
          ..name = '${className}UpdateExtension'
          ..on = refer('ReadQuery<$className>')
          ..methods.addAll([
            Method(
              (m) => m
                ..name = 'update'
                ..returns = refer('Future<void>')
                ..modifier = MethodModifier.async
                ..optionalParameters.addAll(normalFields.map(
                  (field) => Parameter(
                    (p) => p
                      ..name = field.name
                      ..named = true
                      ..type = refer('value<${field.type.getDisplayString(withNullability: true)}>')
                      ..defaultTo = Code('const NoValue()')
                      ..required = false,
                  ),
                ))
                ..body = Code('''await \$query.\$update(
                  where: (_) => whereClause!,
                  values: {
                    ${normalFields.map((e) => 'if (${e.name} is! NoValue) #${e.name}: ${e.name}.val').join(',')},
                  }).execute();'''),
            ),
          ])),

        /// Generate Extension for HasMany creations
        if (parsedEntity.hasManyGetters.isNotEmpty) ...[
          ...parsedEntity.hasManyGetters.map(
            (hasManyField) {
              final hasManyClass = hasManyField.getter!.returnType as InterfaceType;
              final relatedClass = hasManyClass.typeArguments.last.element as ClassElement;
              final relatedClassName = relatedClass.name;

              final parsedRelatedEntity = ParsedEntityClass.parse(relatedClass);
              final referenceField = parsedRelatedEntity.referencedFields
                  .firstWhereOrNull((e) => e.reader.peek('type')!.typeValue.element!.name == className)
                  ?.field;
              if (referenceField == null) {
                throw InvalidGenerationSourceError(
                  'No reference field found for $className in $relatedClassName',
                  element: relatedClass,
                  todo: 'Did you forget to annotate with `@reference`',
                );
              }

              final relatedEntityCreateFields =
                  parsedRelatedEntity.fieldsRequiredForCreate.where((field) => field != referenceField);

              return Extension((b) => b
                ..name = '${className}HasMany${relatedClassName}Extension'
                ..on = refer('HasMany<$className, $relatedClassName>')
                ..methods.addAll([
                  Method(
                    (m) => m
                      ..name = 'add'
                      ..returns = refer('Future<$relatedClassName>')
                      ..optionalParameters.addAll(relatedEntityCreateFields.map(
                        (field) => Parameter((p) => p
                          ..name = field.name
                          ..named = true
                          ..type = refer('${field.type}')
                          ..required = !field.type.isNullable),
                      ))
                      ..body = Code('''return  \$readQuery.\$query.\$insert({
                      ${[
                        ...relatedEntityCreateFields.map((e) => '#${e.name}: ${e.name}'),
                        '#${referenceField.name}: parentId'
                      ].join(',')}
                });'''),
                  ),
                ]));
            },
          )
        ]
      ]));

    return DartFormatter().format([
      '// ignore_for_file: non_constant_identifier_names',
      library.accept(_emitter),
    ].join('\n\n'));
  }

  String _generateConstructorCode(String className, ConstructorElement constructor) {
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

  /// This generates WHERE-EQUAL Clauses for a field
  Method _generateFieldWhereClause(FieldElement field, String className) {
    final dbColumnName = getFieldDbName(field);
    final fieldType = field.type.getDisplayString(withNullability: true);

    return Method(
      (m) {
        m
          ..name = field.name
          ..returns = refer('WhereClauseValue')
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p
            ..name = 'value'
            ..type = refer(fieldType)))
          ..body = Code('\$equal<$fieldType>("$dbColumnName", value)');
      },
    );
  }

  /// This generates GetByProperty for a field
  Method _generateGetByPropertyMethod(FieldElement field, String className) {
    final fieldName = field.name;
    final fieldType = field.type.getDisplayString(withNullability: true);

    return Method(
      (m) {
        m
          ..name = 'findBy${fieldName.pascalCase}'
          ..returns = refer('Future<$className?>')
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p
            ..name = 'val'
            ..type = refer(fieldType)))
          ..body = Code('findOne(where: (q) => q.$fieldName(val))');
      },
    );
  }

  /// Process entity annotation
  String processAnnotation(DartObject constantValue) {
    final classElement = constantValue.type!.element as ClassElement;
    assert(classElement.supertype!.typeArguments.length == 2, 'Should have two type arguments');

    final variable = constantValue.variable;
    if (variable != null) return variable.name;

    final custructor = classElement.constructors.first;
    if (custructor.parameters.isEmpty) {
      return '${classElement.name}()';
    }

    /// TODO(codekeyz): resolve constructor for TypeConverters
    throw UnsupportedError('Parameters for TypeConverters not yet supported');
  }
}
