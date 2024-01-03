library router;

import 'package:grammer/grammer.dart';
import 'package:yaroo/http/http.dart';

import 'definition.dart';

export 'definition.dart' show RouteDefinition;

abstract interface class Route {
  static ControllerRouteMethodDefinition get(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.GET], path));

  static ControllerRouteMethodDefinition head(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.HEAD], path));

  static ControllerRouteMethodDefinition post(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.POST], path));

  static ControllerRouteMethodDefinition put(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.PUT], path));

  static ControllerRouteMethodDefinition delete(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.DELETE], path));

  static ControllerRouteMethodDefinition patch(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.PATCH], path));

  static ControllerRouteMethodDefinition options(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.OPTIONS], path));

  static ControllerRouteMethodDefinition trace(String path, ControllerMethodDefinition defn) =>
      ControllerRouteMethodDefinition(defn, RouteMapping([HTTPMethod.TRACE], path));

  static ControllerRouteMethodDefinition mapping(
    List<HTTPMethod> methods,
    String path,
    ControllerMethodDefinition defn,
  ) {
    var mapping = RouteMapping(methods, path);
    if (methods.contains(HTTPMethod.ALL)) mapping = RouteMapping([HTTPMethod.ALL], path);
    return ControllerRouteMethodDefinition(defn, mapping);
  }

  static RouteGroupDefinition group(String name, {String? prefix}) => RouteGroupDefinition(name, prefix: prefix);

  static UseRouteMiddlewareGroup middleware(String name) => UseRouteMiddlewareGroup(name);

  static RouteGroupDefinition resource(String resource, Type controller, {String? parameterName}) {
    resource = resource.toLowerCase();

    final resourceId = '${(parameterName ?? resource).toSingular().toLowerCase()}Id';

    return Route.group(resource).routes([
      Route.get('/', (controller, #index)),
      Route.get('/<$resourceId>', (controller, #show)),
      Route.post('/', (controller, #create)),
      Route.put('/<$resourceId>', (controller, #update)),
      Route.patch('/<$resourceId>', (controller, #update)),
      Route.delete('/<$resourceId>', (controller, #delete))
    ]);
  }

  static FunctionalRouteDefinition handler(HTTPMethod method, String path, RequestHandlerWithApp handler) =>
      FunctionalRouteDefinition(method, path, handler);

  static FunctionalRouteDefinition notFound(RequestHandlerWithApp handler, [HTTPMethod method = HTTPMethod.ALL]) =>
      FunctionalRouteDefinition(method, '/*', handler);
}
