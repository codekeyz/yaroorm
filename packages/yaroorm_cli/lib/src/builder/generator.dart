import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

// ignore: implementation_imports
import 'package:yaroorm/yaroorm.dart' as entity;
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

  Reference _getReferenceForField(FieldElement f) {
    return f.type.isNullable
        ? refer('Value<${f.type.withNullability}>${!f.type.isNullable ? '?' : ''}')
        : refer(f.type.withNullability);
  }

  Parameter _makeOptional(FieldElement f) {
    return Parameter((p) => p
      ..required = false
      ..defaultTo = Code('const Value.absent()')
      ..named = true
      ..name = f.name
      ..toThis = true);
  }

  Parameter _getParameterForCreate(FieldElement f) {
    if (f.type.isNullable) return _makeOptional(f);

    return Parameter((p) => p
      ..required = true
      ..named = true
      ..name = f.name
      ..toThis = true);
  }

  String _implementClass(ClassElement classElement, ConstantReader annotation) {
    final parsedEntity = ParsedEntityClass.parse(classElement);
    final className = classElement.name;

    final primaryKey = parsedEntity.primaryKey;
    final fields = parsedEntity.allFields;
    final createdAtField = parsedEntity.createdAtField?.field;
    final updatedAtField = parsedEntity.updatedAtField?.field;
    final primaryConstructor = parsedEntity.constructor;
    final bindings = parsedEntity.bindings;
    final normalFields = parsedEntity.normalFields;

    final converters = annotation.peek('converters')!.listValue;

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
          ..returns = refer('EntityTypeDefinition<$className>')
          ..type = MethodType.getter
          ..lambda = true
          ..body = Code(
            '''EntityTypeDefinition<$className>(
                "${parsedEntity.table}",
                timestampsEnabled: ${parsedEntity.timestampsEnabled},
                columns: ${fields.map((field) => generateCodeForField(parsedEntity, field)).toList()},
                mirror: (instance, field) => switch(field) {
                    ${fields.map((e) => '''
                      #${e.name} => instance.${e.name}
                    ''').join(',')},
                      _ => throw Exception('Unknown property \$field'),
                },
                builder: (args) => ${_generateConstructorCode(className, primaryConstructor)},
                ${bindings.isEmpty ? '' : 'bindings: { ${bindings.entries.map(
                  (e) => _generateCodeForBinding(
                    className,
                    e.value.entity.className,
                    e.key,
                    e.value.field,
                    e.value.reader,
                  ),
                ).join(', ')}, },'}
                ${converters.isEmpty ? '' : 'converters: ${converters.map(processAnnotation).toList()},'})''',
          )),

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
            ..initializers.add(Code('super("${getFieldDbName(field)}", order)'))
            ..optionalParameters.add(Parameter((p) => p
              ..type = refer('OrderDirection')
              ..named = true
              ..defaultTo = Code('OrderDirection.asc')
              ..name = 'order')))))),

        /// Generate Create/Update classes for entity
        ..._generateCreateAndUpdateClasses(parsedEntity),

        /// Generate Typed Entity WhereBuilder Extension
        Extension((b) => b
          ..name = '${className}WhereBuilderExtension'
          ..on = refer('WhereClauseBuilder<$className>')
          ..methods.addAll([
            _generateFieldWhereClause(primaryKey.field, className),
            ...normalFields.map((e) => _generateFieldWhereClause(e, className)),
            ..._generateWhereClauseForRelations(parsedEntity),
          ])),

        Extension((b) => b
          ..name = '${className}WhereHelperExtension'
          ..on = refer('Query<$className>')
          ..methods.addAll([
            _generateGetByPropertyMethod(primaryKey.field, className),
            ...normalFields.map((e) => _generateGetByPropertyMethod(e, className)),
          ])),

        /// Generate Extension for loading relations
        Extension((b) => b
          ..name = '${className}RelationsBuilder'
          ..on = refer('JoinBuilder<$className>')
          ..methods.addAll([
            if (parsedEntity.belongsToGetters.isNotEmpty)
              ...parsedEntity.belongsToGetters.map((field) => _generateJoinForBelongsTo(parsedEntity, field.getter!)),
            if (parsedEntity.hasOneGetters.isNotEmpty)
              ...parsedEntity.hasOneGetters.map((field) => _generateJoinForHasOne(parsedEntity, field.getter!)),
            if (parsedEntity.hasManyGetters.isNotEmpty)
              ...parsedEntity.hasManyGetters.map((field) => _generateJoinForHasMany(parsedEntity, field.getter!)),
          ])),

        /// Generate Class for enabling Insert for HasMany creations
        if (parsedEntity.hasManyGetters.isNotEmpty) ...[
          ...parsedEntity.hasManyGetters.map((hasManyField) {
            final hasManyClass = hasManyField.getter!.returnType as InterfaceType;
            final parsedRelatedEntity =
                ParsedEntityClass.parse(hasManyClass.typeArguments.last.element as ClassElement);

            final referenceField =
                parsedRelatedEntity.bindings.entries.firstWhere((e) => e.value.entity.element == parsedEntity.element);

            final relatedEntityCreateFields =
                parsedRelatedEntity.fieldsRequiredForCreate.where((field) => Symbol(field.name) != referenceField.key);

            return Class((b) => b
              ..name = 'New${parsedRelatedEntity.className}For$className'
              ..extend = refer('CreateRelatedEntity<$className, ${parsedRelatedEntity.className}>')
              ..fields.addAll(relatedEntityCreateFields.map(
                (f) => Field((fb) => fb
                  ..name = f.name
                  ..type = _getReferenceForField(f)
                  ..modifier = FieldModifier.final$),
              ))
              ..constructors.add(
                Constructor(
                  (c) => c
                    ..constant = true
                    ..optionalParameters.addAll(
                      relatedEntityCreateFields.map(_getParameterForCreate),
                    ),
                ),
              )
              ..methods.addAll([
                Method((m) => m
                  ..name = 'field'
                  ..returns = refer('Symbol')
                  ..type = MethodType.getter
                  ..type = MethodType.getter
                  ..annotations.add(CodeExpression(Code('override')))
                  ..lambda = true
                  ..body = Code('#${symbolToString(referenceField.key)}')),
                Method(
                  (m) => m
                    ..name = 'toMap'
                    ..returns = refer('Map<Symbol, dynamic>')
                    ..type = MethodType.getter
                    ..annotations.add(CodeExpression(Code('override')))
                    ..lambda = true
                    ..body = Code('{ ${relatedEntityCreateFields.map((e) {
                      if (e.type.isNullable) {
                        return 'if (${e.name}.present) #${e.name} : ${e.name}.value';
                      }
                      return '#${e.name} : ${e.name}';
                    }).join(', ')} }'),
                ),
              ]));
          })
        ],
      ]));

    return DartFormatter().format([
      '// ignore_for_file: non_constant_identifier_names',
      library.accept(_emitter),
    ].join('\n\n'));
  }

  List<Class> _generateCreateAndUpdateClasses(ParsedEntityClass entity) {
    final fieldsRequiredForCreate = entity.fieldsRequiredForCreate;
    return [
      Class(
        (b) => b
          ..name = 'New${entity.className}'
          ..extend = refer('CreateEntity<${entity.className}>')
          ..fields.addAll(fieldsRequiredForCreate.map(
            (f) => Field((fb) => fb
              ..name = f.name
              ..type = _getReferenceForField(f)
              ..modifier = FieldModifier.final$),
          ))
          ..constructors.add(
            Constructor(
              (c) => c
                ..constant = true
                ..optionalParameters.addAll(
                  fieldsRequiredForCreate.map(_getParameterForCreate),
                ),
            ),
          )
          ..methods.add(
            Method(
              (m) => m
                ..name = 'toMap'
                ..returns = refer('Map<Symbol, dynamic>')
                ..type = MethodType.getter
                ..annotations.add(CodeExpression(Code('override')))
                ..lambda = true
                ..body = Code('{ ${fieldsRequiredForCreate.map((e) {
                  if (e.type.isNullable) {
                    return 'if (${e.name}.present) #${e.name}: ${e.name}.value';
                  }
                  return '#${e.name} : ${e.name}';
                }).join(', ')} }'),
            ),
          ),
      ),
      Class((b) => b
        ..name = 'Update${entity.className}'
        ..extend = refer('UpdateEntity<${entity.className}>')
        ..fields.addAll(fieldsRequiredForCreate.map((f) => Field(
              (fb) => fb
                ..name = f.name
                ..type = refer('Value<${f.type.withNullability}>')
                ..modifier = FieldModifier.final$,
            )))
        ..constructors.add(
          Constructor(
            (c) => c
              ..constant = true
              ..optionalParameters.addAll(
                fieldsRequiredForCreate.map(_makeOptional),
              ),
          ),
        )
        ..methods.add(Method(
          (m) => m
            ..name = 'toMap'
            ..returns = refer('Map<Symbol, dynamic>')
            ..type = MethodType.getter
            ..annotations.add(CodeExpression(Code('override')))
            ..lambda = true
            ..body = Code('''{
      ${entity.normalFields.map(
                      (e) => 'if (${e.name}.present) #${e.name}: ${e.name}.value',
                    ).join(',')},
}'''),
        ))),
    ];
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

  /// This generates WHERE-EQUAL clause value for a field
  Method _generateFieldWhereClause(FieldElement field, String className) {
    final dbColumnName = getFieldDbName(field);
    final fieldType = field.type.withNullability;

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

  /// Generate typed Where Filters for entity relations
  List<Method> _generateWhereClauseForRelations(ParsedEntityClass parsed) {
    final result = <Method>[];

    for (final (field) in [...parsed.hasManyGetters, ...parsed.belongsToGetters, ...parsed.hasOneGetters]) {
      final hasMany = field.getter!.returnType as InterfaceType;
      final referencedClass = hasMany.typeArguments.last.element as ClassElement;
      final returnType = 'WhereClauseBuilder<${referencedClass.name}>';

      result.add(
        Method((m) => m
          ..name = field.name
          ..lambda = true
          ..type = MethodType.getter
          ..returns = refer(returnType)
          ..body = Code('$returnType()')),
      );
    }

    return result;
  }

  /// This generates GetByProperty for a field
  Method _generateGetByPropertyMethod(FieldElement field, String className) {
    final fieldName = field.name;
    final fieldType = field.type.withNullability;

    return Method(
      (m) {
        m
          ..name = 'findBy${fieldName.pascalCase}'
          ..returns = refer('Future<$className?>')
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p
            ..name = 'val'
            ..type = refer(fieldType)))
          ..body = Code('findOne(where: (${className.toLowerCase()}) => ${className.toLowerCase()}.$fieldName(val))');
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

  /// Generate DBEntityField for each of the class fields
  String generateCodeForField(ParsedEntityClass parsedClass, FieldElement field) {
    final createdAtField = parsedClass.createdAtField?.field;
    final updatedAtField = parsedClass.updatedAtField?.field;
    final primaryKey = parsedClass.primaryKey;

    final meta = typeChecker(entity.TableColumn).firstAnnotationOf(field, throwOnUnresolved: false);

    final symbol = '#${field.name}';
    final columnName = getFieldDbName(field, meta: meta);
    var unique = false;
    if (meta != null) {
      unique = ConstantReader(meta).peek('unique')?.boolValue ?? false;
    }

    final requiredOpts = '''
              "$columnName",
               ${field.type.withoutNullability},
               $symbol
            ''';

    if (field == createdAtField) {
      return '''DBEntityField.createdAt("$columnName", $symbol)''';
    }

    if (field == updatedAtField) {
      return '''DBEntityField.updatedAt("$columnName", $symbol)''';
    }

    if (field == primaryKey.field) {
      return '''DBEntityField.primaryKey(
          $requiredOpts,
          ${parsedClass.hasAutoIncrementingPrimaryKey ? 'autoIncrement: true' : ''}
          )''';
    }

    final args = [
      requiredOpts,
      if (field.type.isNullable) 'nullable: true',
      if (unique) 'unique: true',
    ].join(',');

    return '''DBEntityField($args)''';
  }

  /// Generate JOIN for BelongsTo getters on Entity
  Method _generateJoinForBelongsTo(
    ParsedEntityClass parent,
    PropertyAccessorElement getter,
  ) {
    final belongsTo = getter.returnType as InterfaceType;
    final getterName = getter.name;
    final relatedClass = ParsedEntityClass.parse(belongsTo.typeArguments.last.element as ClassElement);

    final bindings = parent.bindings;
    if (bindings.isEmpty) {
      throw InvalidGenerationSource(
        'No bindings found to enable BelongsTo relation for ${relatedClass.className} in ${parent.className}. Did you forget to use `@bindTo` ?',
        element: getter,
      );
    }

    /// TODO(codekey): be able to specify binding to use
    final bindingToUse = bindings.entries.firstWhere((e) => e.value.entity.element == relatedClass.element);
    final field = parent.allFields.firstWhere((e) => Symbol(e.name) == bindingToUse.key);
    final foreignField = relatedClass.allFields.firstWhere((e) => Symbol(e.name) == bindingToUse.value.field);

    final joinClass = 'Join<${parent.className}, ${relatedClass.className}>';
    return Method(
      (m) => m
        ..name = getterName
        ..type = MethodType.getter
        ..lambda = true
        ..returns = refer(joinClass)
        ..body = Code('''$joinClass("$getterName",
            origin: (table: "${parent.table}", column: "${getFieldDbName(field)}"),
            on: (table: "${relatedClass.table}", column: "${getFieldDbName(foreignField)}"),
            key: BelongsTo<${parent.className}, ${relatedClass.className}>,
          )'''),
    );
  }

  /// Generate JOIN for HasMany getters on Entity
  Method _generateJoinForHasMany(
    ParsedEntityClass parent,
    PropertyAccessorElement getter,
  ) {
    final hasMany = getter.returnType as InterfaceType;
    final relatedClass = ParsedEntityClass.parse(hasMany.typeArguments.last.element as ClassElement);

    final bindings = relatedClass.bindings;
    if (bindings.isEmpty) {
      throw InvalidGenerationSource(
        'No bindings found to enable HasMany relation for ${relatedClass.className} in ${parent.className}. Did you forget to use `@bindTo` ?',
        element: getter,
      );
    }

    /// TODO(codekey): be able to specify binding to use
    final bindingToUse = bindings.entries.firstWhere((e) => e.value.entity.element == parent.element);
    final foreignField = relatedClass.allFields.firstWhere((e) => Symbol(e.name) == bindingToUse.key);

    final joinClass = 'Join<${parent.className}, ${relatedClass.className}>';
    return Method(
      (m) => m
        ..name = getter.name
        ..type = MethodType.getter
        ..lambda = true
        ..returns = refer(joinClass)
        ..body = Code('''$joinClass("${getter.name}",
            origin: (table: "${parent.table}", column: "${getFieldDbName(parent.primaryKey.field)}"),
            on: (table: "${relatedClass.table}", column: "${getFieldDbName(foreignField)}"),
            key: HasMany<${parent.className}, ${relatedClass.className}>,
          )'''),
    );
  }

  /// Generate JOIN for HasOne getters on Entity
  Method _generateJoinForHasOne(
    ParsedEntityClass parent,
    PropertyAccessorElement getter,
  ) {
    final hasOne = getter.returnType as InterfaceType;
    final getterName = getter.name;
    final relatedClass = ParsedEntityClass.parse(hasOne.typeArguments.last.element as ClassElement);

    final bindings = parent.bindings;
    if (bindings.isEmpty) {
      throw InvalidGenerationSource(
        'No bindings found to enable HasOne relation for ${relatedClass.className} in ${parent.className}. Did you forget to use `@bindTo` ?',
        element: getter,
      );
    }

    /// TODO(codekey): be able to specify binding to use
    final bindingToUse = bindings.entries.firstWhere((e) => e.value.entity.element == relatedClass.element);
    final field = parent.allFields.firstWhere((e) => Symbol(e.name) == bindingToUse.key);
    final foreignField = relatedClass.allFields.firstWhere((e) => Symbol(e.name) == bindingToUse.value.field);

    final joinClass = 'Join<${parent.className}, ${relatedClass.className}>';
    return Method(
      (m) => m
        ..name = getterName
        ..type = MethodType.getter
        ..lambda = true
        ..returns = refer(joinClass)
        ..body = Code('''$joinClass("$getterName",
            origin: (table: "${parent.table}", column: "${getFieldDbName(field)}"),
            on: (table: "${relatedClass.table}", column: "${getFieldDbName(foreignField)}"),
            key: HasOne<${parent.className}, ${relatedClass.className}>,
          )'''),
    );
  }

  String _generateCodeForBinding(
    String className,
    String relatedClass,
    Symbol field,
    Symbol on,
    ConstantReader reader,
  ) {
    final onUpdate = reader.peek('onUpdate')?.objectValue.variable!.name;
    final onDelete = reader.peek('onDelete')?.objectValue.variable!.name;

    return '''
        #${symbolToString(field)} : Binding<$className, $relatedClass>(
          ${[
      'on: #${symbolToString(on)}',
      if (onUpdate != null) 'onUpdate: ForeignKeyAction.$onUpdate',
      if (onDelete != null) 'onDelete: ForeignKeyAction.$onDelete',
    ].join(', ')} ,)''';
  }
}

extension on DartType {
  // ignore: deprecated_member_use
  String get withNullability => getDisplayString(withNullability: true);

  // ignore: deprecated_member_use
  String get withoutNullability => getDisplayString(withNullability: false);
}
