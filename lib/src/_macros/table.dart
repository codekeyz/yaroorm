import 'dart:async';

import 'package:macros/macros.dart';
import 'package:meta/meta_meta.dart';

import '../database/entity/entity.dart';

@Target({TargetKind.classType})
macro class Table implements ClassDeclarationsMacro, ClassDefinitionMacro {
  final String? name;
  final List<EntityTypeConverter> converters;

  const Table({this.name, this.converters = const []});

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    await [
      _declareQuery(clazz, builder),
      _declareSchema(clazz, builder),
      // _declareTypeInfo(clazz, builder),
    ].wait;
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder typeBuilder,
  ) async {
    final clazzMethods = await typeBuilder.methodsOf(clazz);
    final (queryMethod, schemaMethod, typeInfoMethod) = (
      clazzMethods.firstWhere((e) => e.identifier.name == 'query'),
      clazzMethods.firstWhere((e) => e.identifier.name == 'schema'),
      clazzMethods.firstWhere((e) => e.identifier.name == 'typeInfo'),
    );

    final (queryBuilder, schemaBuilder, typeInfoBuilder) = await (
      typeBuilder.buildMethod(queryMethod.identifier),
      typeBuilder.buildMethod(schemaMethod.identifier),
      typeBuilder.buildMethod(typeInfoMethod.identifier),
    ).wait;

    final (dbIdentifier, schemaIdentifier, typeDefIdentifier) = await (
      typeBuilder.resolveIdentifier(Uri.parse('package:yaroorm/src/database/database.dart'), 'DB'),
      typeBuilder.resolveIdentifier(Uri.parse('package:yaroorm/src/migration.dart'), 'Schema'),
      typeBuilder.resolveIdentifier(Uri.parse('package:yaroorm/src/reflection.dart'), 'EntityTypeDefinition'),
    ).wait;

    /// Generate Entity.query
    final queryParts = <Object>[
      ' => ',
      NamedTypeAnnotationCode(name: dbIdentifier),
      '.query<',
      NamedTypeAnnotationCode(name: clazz.identifier),
      '>',
      name != null ? '("$name");' : '();',
    ];
    queryBuilder.augment(FunctionBodyCode.fromParts(queryParts));

    /// Generate Entity.schema
    final schemaParts = <Object>[
      ' => ',
      NamedTypeAnnotationCode(name: schemaIdentifier),
      '.fromEntity<',
      NamedTypeAnnotationCode(name: clazz.identifier),
      '>();',
    ];
    schemaBuilder.augment(FunctionBodyCode.fromParts(schemaParts));

    /// Generate Entity.schema
    // final typeInfoParts = <Object>[
    //   ' => ',
    //   NamedTypeAnnotationCode(
    //     name: typeDefIdentifier,
    //     typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)],
    //   ),
    //   '("hello_world"',
    //   ');',
    // ];
    // typeInfoMethod.augment(FunctionBodyCode.fromParts(typeInfoParts));
  }

  Future<void> _declareQuery(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final queryIdentifier = await builder.resolveIdentifier(
      Uri.parse('package:yaroorm/src/query/query.dart'),
      'Query',
    );

    // Declare a static method which takes all required providers, and returns
    // a provider for this class.
    final parts = <Object>[
      ' external static ',
      NamedTypeAnnotationCode(name: queryIdentifier, typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)]),
      ' get query;',
    ];

    builder.declareInType(DeclarationCode.fromParts(parts));
  }

  Future<void> _declareSchema(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final migrationUri = Uri.parse('package:yaroorm/src/migration.dart');
    final (createSchemaIdentifier, schemaIdentifier) = await (
      builder.resolveIdentifier(migrationUri, 'CreateSchema'),
      builder.resolveIdentifier(migrationUri, 'Schema'),
    ).wait;

    final parts = <Object>[
      ' external static ',
      NamedTypeAnnotationCode(
          name: createSchemaIdentifier, typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)]),
      ' get schema;',
    ];

    builder.declareInType(DeclarationCode.fromParts(parts));
  }

  Future<void> _declareTypeInfo(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final typeDefIdentifier = await builder.resolveIdentifier(
      Uri.parse('package:yaroorm/src/reflection.dart'),
      'EntityTypeDefinition',
    );

    final parts = <Object>[
      ' external static ',
      NamedTypeAnnotationCode(
          name: typeDefIdentifier, typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)]),
      ' get typeInfo;',
    ];

    builder.declareInType(DeclarationCode.fromParts(parts));
  }
}
