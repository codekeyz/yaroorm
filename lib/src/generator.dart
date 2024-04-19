import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

// ignore: implementation_imports
import 'database/entity/entity.dart' as entity;

class YaroormOptions {
  YaroormOptions.fromOptions([BuilderOptions? options]);
}

Builder generatorFactoryBuilder(BuilderOptions options) => SharedPartBuilder(
      [YaroormGenerator(YaroormOptions.fromOptions(options))],
      'yaroorm',
    );

typedef FieldData = ({FieldElement field, ConstantReader reader});

class YaroormGenerator extends GeneratorForAnnotation<entity.Table> {
  final YaroormOptions globalOptions;

  YaroormGenerator(this.globalOptions);

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
      );
    }

    return _implementClass(element, annotation);
  }

  FieldData? _getFieldAnnotationByType(
    List<FieldElement> fields,
    Type type,
  ) {
    for (final field in fields) {
      final result = _typeChecker(type).firstAnnotationOf(field, throwOnUnresolved: false);
      if (result != null) {
        return (field: field, reader: ConstantReader(result));
      }
    }
    return null;
  }

  String _implementClass(ClassElement classElement, ConstantReader annotation) {
    final getterFields = classElement.fields.where((e) => e.getter?.isSynthetic == false);
    final hasManyGetters = getterFields.where((getter) => _typeChecker(entity.HasMany).isExactlyType(getter.type));

    if (hasManyGetters.isNotEmpty) {
      final hasManyClass = hasManyGetters.first.type.element;
      print(hasManyClass?.name);
    }

    final fields = classElement.fields.where(allowedTypes).toList();
    final className = classElement.name;

    final tableName = annotation.peek('name')!.stringValue;

    final primaryKey = _getFieldAnnotationByType(fields, entity.PrimaryKey);
    final createdAtField = _getFieldAnnotationByType(fields, entity.CreatedAtColumn)?.field;
    final updatedAtField = _getFieldAnnotationByType(fields, entity.UpdatedAtColumn)?.field;

    final converters = annotation.peek('converters')!.listValue;

    if (primaryKey == null) {
      throw Exception("$className Entity doesn't have primary key");
    }

    final autoIncrementPrimaryKey = primaryKey.reader.peek('autoIncrement')!.boolValue;
    final timestampsEnabled = (createdAtField ?? updatedAtField) != null;

    /// other properties aside primarykey, updatedAt and createdAt
    final normalFields = fields.where((e) => ![createdAtField, updatedAtField, primaryKey.field].contains(e));

    final creatableFields = [if (!autoIncrementPrimaryKey) primaryKey.field, ...normalFields];

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

    String generateCodeForField(FieldElement e) {
      final symbol = '#${e.name}';
      final columnName = _getFieldDbName(e);

      final meta = _typeChecker(entity.TableColumn).firstAnnotationOf(e, throwOnUnresolved: false);

      final requiredOpts = '''
              "$columnName",
               ${e.type.getDisplayString(withNullability: false)},
               $symbol
            ''';

      if (meta != null) {
        final metaReader = ConstantReader(meta);
        final isReferenceField = _typeChecker(entity.reference).isExactly(meta.type!.element!);

        if (isReferenceField) {
          final referencedType = metaReader.peek('type')!.typeValue;
          final element = referencedType.element as ClassElement;
          final superType = element.supertype?.element;

          if (superType == null || !_typeChecker(entity.Entity).isExactly(superType)) {
            throw InvalidGenerationSourceError(
              'Generator cannot target field `${e.name}` on `$className` class.',
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

    final typeDataName = '${className.snakeCase}TypeData';
    final queryName = '${className}Query';

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
            ..initializers.add(Code('super("${_getFieldDbName(field)}", direction)'))
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
      ]));

    final emitter = DartEmitter(useNullSafetySyntax: true, orderDirectives: true);
    return DartFormatter().format([
      '// ignore_for_file: non_constant_identifier_names',
      library.accept(emitter),
    ].join('\n\n'));
  }

  bool allowedTypes(FieldElement field) {
    return field.getter?.isSynthetic ?? false;
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
    final dbColumnName = _getFieldDbName(field);
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

extension DartTypeExt on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;
}

String _getFieldDbName(FieldElement element) {
  final elementName = element.name;
  final meta = _typeChecker(entity.TableColumn).firstAnnotationOf(element, throwOnUnresolved: false);
  if (meta != null) {
    return ConstantReader(meta).peek('name')?.stringValue ?? elementName;
  }
  return elementName;
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

TypeChecker _typeChecker(Type type) => TypeChecker.fromRuntime(type);
