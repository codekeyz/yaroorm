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

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder typeBuilder,
  ) async {
    final queryMethod = (await typeBuilder.methodsOf(clazz)).firstWhere((e) => e.identifier.name == 'query');
    final builder = await typeBuilder.buildMethod(queryMethod.identifier);

    final dbIdentifier = await typeBuilder.resolveIdentifier(
      Uri.parse('package:yaroorm/src/database/database.dart'),
      'DB',
    );

    final parts = <Object>[
      ' => ',
      NamedTypeAnnotationCode(name: dbIdentifier),
      '.query<',
      NamedTypeAnnotationCode(name: clazz.identifier),
      '>',
      name != null ? '("$name");' : '();',
    ];

    builder.augment(FunctionBodyCode.fromParts(parts));
  }
}
