library router;

import 'package:pharaoh/pharaoh.dart';
import 'definition.dart';

export 'definition.dart';

typedef ClassMethodDefinition = (Type controller, Symbol symbol);

abstract interface class Router {
  static RouteMethodDefinition get(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.GET], path));

  static RouteMethodDefinition head(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.HEAD], path));

  static RouteMethodDefinition post(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.POST], path));

  static RouteMethodDefinition put(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.PUT], path));

  static RouteMethodDefinition delete(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.DELETE], path));

  static RouteMethodDefinition patch(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.PATCH], path));

  static RouteMethodDefinition options(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.OPTIONS], path));

  static RouteMethodDefinition trace(String path, ClassMethodDefinition defn) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.TRACE], path));

  static RouteMethodDefinition mapping(
    List<HTTPMethod> methods,
    String path,
    ClassMethodDefinition defn,
  ) {
    var mapping = RouteMapping(methods, path);
    if (methods.contains(HTTPMethod.ALL)) mapping = RouteMapping([HTTPMethod.ALL], path);
    return RouteMethodDefinition(defn, mapping);
  }

  static RouteGroupDefinition group(
    String prefix, {
    List<MiddlewareDefinition> middlewares = const [],
  }) =>
      RouteGroupDefinition('/$prefix', methods: const [], middlewares: middlewares);

  static RouteGroupDefinition resource(
    String resource,
    Type controller, {
    String? parameterName,
  }) {
    resource = resource.toLowerCase();
    final paramName = parameterName ?? resource;

    return Router.group(resource).routes([
      Router.get('/', (controller, #index)),
      Router.get('/<$paramName>', (controller, #show)),
      Router.post('/', (controller, #create)),
      Router.put('/<$paramName>', (controller, #update)),
      Router.patch('/<$paramName>', (controller, #update)),
      Router.delete('/<$paramName>', (controller, #delete))
    ]);
  }
}
