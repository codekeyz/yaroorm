import 'package:meta/meta.dart';
import 'package:yaroo/foundation/validation.dart';
import 'package:yaroo/http/_pharaoh.dart';
import 'package:yaroo/http/meta.dart';

import '../_reflector/reflector.dart';
import '../core.dart';
import 'utils.dart';

enum RouteDefinitionType { route, group, middleware }

class RouteMapping {
  final List<HTTPMethod> methods;
  final String _path;

  @visibleForTesting
  String get stringVal => '${methods.map((e) => e.name).toList()}: $_path';

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

class UseRouteMiddlewareGroup {
  final String alias;

  UseRouteMiddlewareGroup(this.alias);

  RouteGroupDefinition group(String name, {String? prefix}) {
    final middlewares = ApplicationFactory.resolveMiddlewareForGroup(alias);
    return RouteGroupDefinition(name, prefix: prefix, middlewares: middlewares);
  }
}

class _MiddlewareDefinition extends RouteDefinition {
  final HandlerFunc mdw;

  _MiddlewareDefinition(this.mdw, RouteMapping route) : super(RouteDefinitionType.middleware) {
    this.route = route;
  }

  @override
  void commit(Spanner spanner) => spanner.addMiddleware(route.path, mdw);
}

typedef ControllerMethodDefinition = (Type controller, Symbol symbol);

class ControllerMethod {
  final ControllerMethodDefinition method;
  final List<ControllerMethodParam> params;

  String get methodName => symbolToString(method.$2);

  Type get controller => method.$1;

  ControllerMethod(this.method, [this.params = const []]);
}

class ControllerMethodParam {
  final String name;
  final Type type;
  final bool optional;
  final dynamic defaultValue;
  final RequestAnnotation? meta;

  final BaseDTO? dto;

  const ControllerMethodParam(this.name, this.type, {this.meta, this.optional = false, this.defaultValue, this.dto});
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
    final handler = ApplicationFactory.buildControllerMethod(method);
    for (final routeMethod in route.methods) {
      spanner.addRoute(routeMethod, route.path, useRequestHandler(handler));
    }
  }
}

class RouteGroupDefinition extends RouteDefinition {
  final String name;
  final List<RouteDefinition> defns = [];

  List<String> get paths => defns.map((e) => e.route.stringVal).toList();

  RouteGroupDefinition(
    this.name, {
    String? prefix,
    Iterable<HandlerFunc> middlewares = const [],
    Iterable<RouteDefinition> definitions = const [],
  }) : super(RouteDefinitionType.group) {
    route = RouteMapping([HTTPMethod.ALL], '/${prefix ?? name.toLowerCase()}');

    /// add middlewares
    if (middlewares.isNotEmpty) {
      final groupMdw = middlewares.reduce((value, e) => value.chain(e));
      defns.add(_MiddlewareDefinition(groupMdw, route));
    }

    /// add routes
    _unwrapRoutes(definitions);
  }

  void _unwrapRoutes(Iterable<RouteDefinition> routes) {
    for (final subRoute in routes) {
      if (subRoute is! RouteGroupDefinition) {
        defns.add(subRoute._prefix(route.path));
        continue;
      }

      for (var e in subRoute.defns) {
        defns.add(e._prefix(route.path));
      }
    }
  }

  RouteGroupDefinition routes(List<RouteDefinition> subRoutes) {
    return this.._unwrapRoutes(subRoutes);
  }

  @override
  void commit(Spanner spanner) {
    for (final mdw in defns) {
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
