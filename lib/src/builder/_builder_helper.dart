import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class PHaraohTurboValidator extends ArgumentError {}

class ControllerVisitor extends RecursiveAstVisitor<void> {
  final List<Symbol> constructorDep = [];
  final List<Symbol> methods = [];

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    for (final param in node.parameters.parameters) {
      if (param is SimpleFormalParameter && param.type is NamedType) {
        constructorDep.add(Symbol(param.type.toString()));
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methods.add(Symbol(node.name.toString()));
  }
}
