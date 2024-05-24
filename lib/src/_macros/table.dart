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
    await _declareQuery(clazz, builder);
    await _declareSchema(clazz, builder);
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder typeBuilder,
  ) async {
    final queryMethod = (await typeBuilder.methodsOf(clazz)).firstWhere((e) => e.identifier.name == 'query');
    final schemaMethod = (await typeBuilder.methodsOf(clazz)).firstWhere((e) => e.identifier.name == 'schema');

    final queryBuilder = await typeBuilder.buildMethod(queryMethod.identifier);
    final schemaBuilder = await typeBuilder.buildMethod(schemaMethod.identifier);

    /// Generate Entity.query
    final dbIdentifier = await typeBuilder.resolveIdentifier(
      Uri.parse('package:yaroorm/src/database/database.dart'),
      'DB',
    );
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
    final schemaIdentifier = await typeBuilder.resolveIdentifier(
      Uri.parse('package:yaroorm/src/migration.dart'),
      'Schema',
    );
    final schemaParts = <Object>[
      ' => ',
      NamedTypeAnnotationCode(name: schemaIdentifier),
      '.fromEntity<',
      NamedTypeAnnotationCode(name: clazz.identifier),
      '>();',
    ];
    schemaBuilder.augment(FunctionBodyCode.fromParts(schemaParts));
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
      NamedTypeAnnotationCode(name: createSchemaIdentifier, typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)]),
      ' get schema;',
    ];

    builder.declareInType(DeclarationCode.fromParts(parts));
  }
}
