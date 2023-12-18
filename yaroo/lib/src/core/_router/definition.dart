import 'package:pharaoh/pharaoh.dart';

import '../_reflector/reflector.dart';
import '../core.dart';
import 'utils.dart';

enum RouteDefinitionType { route, group, middleware }

class RouteMapping {
  final List<HTTPMethod> methods;
  final String _path;

  String get path => cleanRoute(_path);

  const RouteMapping(this.methods, this._path);

  RouteMapping prefix(String prefix) => RouteMapping(methods, '$prefix$_path');
}

abstract class RouteDefinition {
  late RouteMapping route;
  final RouteDefinitionType type;

  RouteDefinition(this.type);

  void commit(Spanner spanner);

  RouteDefinition _prefix(String prefix) => this..route = route.prefix(prefix);
}

class _MiddlewareDefinition extends RouteDefinition {
  final Middleware mdw;

  _MiddlewareDefinition(this.mdw, RouteMapping route) : super(RouteDefinitionType.middleware) {
    this.route = route;
  }

  @override
  void commit(Spanner spanner) => spanner.addMiddleware(route.path, mdw);
}

typedef ControllerMethodDefinition = (Type controller, Symbol symbol);

class ControllerMethod {
  final ControllerMethodDefinition classMethod;
  final List<Type> parameters = [];

  ControllerMethod(this.classMethod);
}

class ControllerRouteMethodDefinition extends RouteDefinition {
  final ControllerMethod method;

  ControllerRouteMethodDefinition(ControllerMethodDefinition defn, RouteMapping mapping)
      : method = parseControllerMethod(defn),
        super(RouteDefinitionType.route) {
    route = mapping;
  }

  @override
  void commit(Spanner spanner) {
    for (final routeMethod in route.methods) {
      spanner.addRoute(
        routeMethod,
        route.path,
        useRequestHandler(_controllerHandler(method)),
      );
    }
  }
}

class RouteGroupDefinition extends RouteDefinition {
  final String name;
  final List<RouteDefinition> definitions = [];

  RouteGroupDefinition(
    this.name, {
    String? prefix,
    List<Middleware> middlewares = const [],
    List<RouteDefinition> definitions = const [],
  }) : super(RouteDefinitionType.group) {
    route = RouteMapping([HTTPMethod.ALL], '/${prefix ?? name.toLowerCase()}');

    /// add middlewares
    if (middlewares.isNotEmpty) {
      final groupMdw = middlewares.reduce((value, e) => value.chain(e));
      this.definitions.add(_MiddlewareDefinition(groupMdw, route));
    }

    /// add routes
    this.definitions.addAll(definitions.map((e) => e._prefix(route.path)));
  }

  RouteGroupDefinition routes(List<RouteDefinition> subRoutes) {
    for (final subRoute in subRoutes) {
      if (subRoute is! RouteGroupDefinition) {
        definitions.add(subRoute._prefix(route.path));
        continue;
      }

      for (var e in subRoute.definitions) {
        definitions.add(e._prefix(route.path));
      }
    }
    return this;
  }

  @override
  void commit(Spanner spanner) {
    for (final mdw in definitions) {
      mdw.commit(spanner);
    }
  }
}

class FunctionalRouteDefinition extends RouteDefinition {
  final RequestHandler handler;
  final HTTPMethod method;
  final String path;

  FunctionalRouteDefinition(this.method, this.path, this.handler) : super(RouteDefinitionType.route) {
    route = RouteMapping([method], path);
  }

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
