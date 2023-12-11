import 'dart:mirrors';

import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';

import '../core.dart';
import 'router.dart';
import 'utils.dart';

extension on ControllerMethodDefinition {
  void validate() {
    final ctrlMirror = reflectClass($1);

    if (ctrlMirror.superclass?.reflectedType != BaseController) {
      throw ArgumentError('${$1} must extend BaseController');
    }

    final methods = ctrlMirror.instanceMembers.values.whereType<MethodMirror>();
    if (!methods.any((e) => e.simpleName == $2)) {
      throw ArgumentError('${$1} does not have method ${symbolToString($2)}');
    }
  }
}

enum RouteDefinitionType { route, group, middleware }

class RouteMapping {
  final List<HTTPMethod> methods;
  final String _path;

  String get path => cleanRoute(_path);

  const RouteMapping(this.methods, this._path);

  RouteMapping prefix(String prefix) => RouteMapping(methods, '$prefix$_path');
}

class MiddlewareDefinition extends RouteDefinition {
  final Middleware mdw;
  final RouteMapping mapping;

  MiddlewareDefinition(this.mdw, this.mapping) : super(RouteDefinitionType.middleware);

  MiddlewareDefinition prefix(String prefix) => MiddlewareDefinition(
        mdw,
        mapping.prefix(prefix),
      );

  @override
  void commit(Spanner spanner) {
    spanner.addMiddleware(mapping.path, mdw);
  }
}

class RouteMethodDefinition extends RouteDefinition {
  final ControllerMethodDefinition classMethod;
  final RouteMapping mapping;

  RouteMethodDefinition(this.classMethod, this.mapping)
      : super(RouteDefinitionType.route) {
    classMethod.validate();
  }

  RouteMethodDefinition prefix(String prefix) =>
      RouteMethodDefinition(classMethod, mapping.prefix(prefix));

  @override
  void commit(Spanner spanner) {
    for (final method in mapping.methods) {
      spanner.addRoute(method, mapping.path, classMethod);
    }
  }
}

class RouteGroupDefinition extends RouteDefinition {
  final String name;
  List<MiddlewareDefinition> middlewareDefinitions = [];
  List<RouteMethodDefinition> methodDefinitions = [];

  RouteGroupDefinition(
    this.name, {
    List<MiddlewareDefinition> middlewares = const [],
    List<RouteMethodDefinition> methods = const [],
    String? prefix,
  }) : super(RouteDefinitionType.group) {
    final groupPrefix = prefix ?? name.toLowerCase();
    methodDefinitions = methods.map((e) => e.prefix(groupPrefix)).toList();
    middlewareDefinitions = middlewares.map((e) => e.prefix(groupPrefix)).toList();
  }

  RouteGroupDefinition routes(List<RouteMethodDefinition> methods) =>
      RouteGroupDefinition(
        name,
        methods: methods,
        middlewares: middlewareDefinitions,
      );

  RouteGroupDefinition prefix(String prefix) => RouteGroupDefinition(
        name,
        methods: methodDefinitions,
        middlewares: middlewareDefinitions,
        prefix: prefix.toLowerCase(),
      );

  @override
  void commit(Spanner spanner) {
    for (final mdw in middlewareDefinitions) {
      mdw.commit(spanner);
    }
    for (final defn in methodDefinitions) {
      defn.commit(spanner);
    }
  }
}

extension RouteDefinitionExtension on Iterable<RouteDefinition> {
  List<RouteDefinition> get compressed {
    final compressedList = <RouteDefinition>[];
    for (final defn in this) {
      switch (defn.type) {
        case RouteDefinitionType.group:
          defn as RouteGroupDefinition;
          compressedList
            ..addAll(defn.middlewareDefinitions)
            ..addAll(defn.methodDefinitions);
          break;
        default:
          compressedList.add(defn);
      }
    }
    return compressedList;
  }

  List<RouteMethodDefinition> get methods =>
      compressed.whereType<RouteMethodDefinition>().toList();

  List<MiddlewareDefinition> get middlewares =>
      compressed.whereType<MiddlewareDefinition>().toList();
}
