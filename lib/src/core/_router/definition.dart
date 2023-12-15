import 'package:pharaoh/pharaoh.dart';

import '../_reflector/reflector.dart';
import '../core.dart';
import 'router.dart';
import 'utils.dart';

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
  void commit(Spanner spanner) => spanner.addMiddleware(mapping.path, mdw);
}

class ControllerMethod {
  final ControllerMethodDefinition classMethod;
  final List<Type> parameters = [];

  ControllerMethod(this.classMethod);
}

class ControllerRouteMethodDefinition extends RouteDefinition {
  final ControllerMethod method;
  final RouteMapping mapping;

  ControllerRouteMethodDefinition(ControllerMethodDefinition defn, this.mapping)
      : method = parseControllerMethod(defn),
        super(RouteDefinitionType.route);

  ControllerRouteMethodDefinition prefix(String prefix) =>
      ControllerRouteMethodDefinition(method.classMethod, mapping.prefix(prefix));

  @override
  void commit(Spanner spanner) {
    for (final routeMethod in mapping.methods) {
      spanner.addRoute(
        routeMethod,
        mapping.path,
        useRequestHandler(_controllerHandler(method)),
      );
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

RequestHandler _controllerHandler(ControllerMethod method) {
  final defn = method.classMethod;

  return (req, res) async {
    final instance = createNewInstance<BaseController>(defn.$1);
    final mirror = inject.reflect(instance);

    final result = await Future.sync(
      () => mirror.invoke(symbolToString(defn.$2), [req, res]),
    );

    return result;
  };
}
