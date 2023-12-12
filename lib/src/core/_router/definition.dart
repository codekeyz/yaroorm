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

class ControllerRouteMethodDefinition extends RouteDefinition {
  final ControllerMethodDefinition classMethod;
  final RouteMapping mapping;

  ControllerRouteMethodDefinition(this.classMethod, this.mapping)
      : super(RouteDefinitionType.route) {
    classMethod.validate();
  }

  ControllerRouteMethodDefinition prefix(String prefix) =>
      ControllerRouteMethodDefinition(classMethod, mapping.prefix(prefix));

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
  List<ControllerRouteMethodDefinition> controllerDefns = [];
  List<FunctionalRouteDefinition> functionDefns = [];

  RouteGroupDefinition(
    this.name, {
    List<MiddlewareDefinition> middlewares = const [],
    List<ControllerRouteMethodDefinition> controllerDefns = const [],
    this.functionDefns = const [],
    String? prefix,
  }) : super(RouteDefinitionType.group) {
    final groupPrefix = prefix ?? name.toLowerCase();
    this.controllerDefns = controllerDefns.map((e) => e.prefix(groupPrefix)).toList();
    middlewareDefinitions = middlewares.map((e) => e.prefix(groupPrefix)).toList();
  }

  RouteGroupDefinition routes(List<RouteDefinition> routes) => RouteGroupDefinition(
        name,
        controllerDefns: routes.whereType<ControllerRouteMethodDefinition>().toList(),
        functionDefns: routes.whereType<FunctionalRouteDefinition>().toList(),
        middlewares: middlewareDefinitions,
      );

  RouteGroupDefinition prefix(String prefix) => RouteGroupDefinition(
        name,
        controllerDefns: controllerDefns,
        functionDefns: functionDefns,
        middlewares: middlewareDefinitions,
        prefix: prefix.toLowerCase(),
      );

  @override
  void commit(Spanner spanner) {
    for (final mdw in middlewareDefinitions) {
      mdw.commit(spanner);
    }
    for (final defn in [...controllerDefns, ...functionDefns]) {
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
            ..addAll(defn.controllerDefns)
            ..addAll(defn.functionDefns);
          break;
        default:
          compressedList.add(defn);
      }
    }
    return compressedList;
  }

  List<MiddlewareDefinition> get middlewares =>
      compressed.whereType<MiddlewareDefinition>().toList();

  List<RouteDefinition> get reqHandlers {
    return compressed.where((e) => e is! MiddlewareDefinition).toList();
  }
}

class FunctionalRouteDefinition extends RouteDefinition {
  final RequestHandler handler;
  final HTTPMethod method;
  final String path;

  const FunctionalRouteDefinition(this.method, this.path, this.handler)
      : super(RouteDefinitionType.route);

  @override
  void commit(Spanner spanner) {
    spanner.addRoute(method, path, useRequestHandler(handler));
  }
}
