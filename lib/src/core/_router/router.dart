library router;

import 'package:spanner/spanner.dart';
import 'definition.dart';

export 'definition.dart' show RouteDefinitionExtension;

typedef ControllerMethodDefinition = (Type controller, Symbol symbol);

abstract class RouteDefinition {
  final RouteDefinitionType type;
  const RouteDefinition(this.type);

  void commit(Spanner spanner);
}

abstract interface class Route {
  static RouteMethodDefinition get(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.GET], path));

  static RouteMethodDefinition head(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.HEAD], path));

  static RouteMethodDefinition post(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.POST], path));

  static RouteMethodDefinition put(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.PUT], path));

  static RouteMethodDefinition delete(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.DELETE], path));

  static RouteMethodDefinition patch(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.PATCH], path));

  static RouteMethodDefinition options(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.OPTIONS], path));

  static RouteMethodDefinition trace(
    String path,
    ControllerMethodDefinition defn,
  ) =>
      RouteMethodDefinition(defn, RouteMapping([HTTPMethod.TRACE], path));

  static RouteMethodDefinition mapping(
    List<HTTPMethod> methods,
    String path,
    ControllerMethodDefinition defn,
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

    return Route.group(resource).routes([
      Route.get('/', (controller, #index)),
      Route.get('/<$paramName>', (controller, #show)),
      Route.post('/', (controller, #create)),
      Route.put('/<$paramName>', (controller, #update)),
      Route.patch('/<$paramName>', (controller, #update)),
      Route.delete('/<$paramName>', (controller, #delete))
    ]);
  }
}
