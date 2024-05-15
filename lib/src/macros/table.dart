import 'dart:async';

import 'package:macros/macros.dart';

import '../../yaroorm.dart';

// @Target({TargetKind.classType})
macro class Table implements ClassDeclarationsMacro, ClassDefinitionMacro {
  final String? name;
  final List<EntityTypeConverter> converters;

  const Table({
    this.name,
    this.converters = const [],
  });

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async  {
    // Give an error if the user wrote their own `toString`, there isn't
    // anything sensible for us to do in this case.
    final methods = await builder.methodsOf(clazz);


    print(await builder.fieldsOf(clazz));

    for (var method in methods) {
      if (method.identifier.name == 'toString') {
        throw DiagnosticException(Diagnostic(
            DiagnosticMessage(
                'Cannot generate toString due to existing declaration',
                target: method.asDiagnosticTarget),
            Severity.error));
      }
    }

    final (override, string) = await (
      // ignore: deprecated_member_use
      builder.resolveIdentifier(_dartCore, 'override'),
      // ignore: deprecated_member_use
      builder.resolveIdentifier(_dartCore, 'String'),
    ).wait;
    builder.declareInType(DeclarationCode.fromParts(
        ['@', override, '\n  ', string, ' toString();']));
  }

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async  {
    final methods = await builder.methodsOf(clazz);
    final toString = methods.firstWhere((m) => m.identifier.name == 'toString');
    final toStringBuilder = await builder.buildMethod(toString.identifier); 
    //
    // Note that we don't surface getters, only true fields. Pure getters would
    // appear in the methods list.
    final fields = await builder.fieldsOf(clazz);
    toStringBuilder.augment(FunctionBodyCode.fromParts([
      '{\n',
      '    // You can add breakpoints here!\n',
      '    return """\n${clazz.identifier.name} {\n',
      for (var field in fields)
        if (!field.hasStatic) ...[
          '  ${field.identifier.name}: \${',
          field.identifier,
          '}\n',
        ],
      '}""";\n',
      '  }'
    ]));
  }
}

void main () {}

final _dartCore = Uri(scheme: 'dart', path: 'core');
