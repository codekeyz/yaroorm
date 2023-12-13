import 'dart:isolate';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

abstract class JsonType {}

final typeMap = <String, Type>{
  'String': String,
  'int': int,
  'num': num,
  'double': double,
};

class ClassVisitor extends RecursiveAstVisitor<void> {
  List<ModelField> params = [];
  late final String className;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    className = node.name.toString();
    super.visitClassDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final type = node.fields.type;
    final variables = node.fields.variables;

    if (type is! NamedType) {
      throw Exception('Invalid type in model definition');
    }

    final dartType = type.typeArguments == null ? typeMap[type.toString()]! : JsonType;
    for (final variable in variables) {
      params.add(ModelField(variable.name.toString(), Field(dartType)));
    }
  }
}

class Model {
  final String name;
  final List<ModelField> fields;
  const Model(this.name, this.fields);

  Map<String, dynamic> toJson() => {
        'name': name,
        'fields': fields.map((e) => e.toJson()).toList(),
      };
}

class ModelField {
  final Field field;
  final String name;
  const ModelField(this.name, this.field);

  Map<String, dynamic> toJson() => {'name': name, 'field': field.toJson()};
}

class Field {
  final Type type;
  final bool isModel;
  const Field(this.type, {this.isModel = false});

  Map<String, dynamic> toJson() => {'type': type, 'isModel': isModel};
}

Future<Model> parseModelFile(String filePath) async {
  final classVisitor = ClassVisitor();
  final result = await Isolate.run(
      () => parseFile(path: filePath, featureSet: FeatureSet.latestLanguageVersion()));
  result.unit.accept(classVisitor);
  return Model(classVisitor.className, classVisitor.params);
}
