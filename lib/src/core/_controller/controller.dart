abstract class BaseController {}

// import 'dart:mirrors';

// import 'package:collection/collection.dart';
// import 'package:pharaoh/pharaoh.dart';
// import 'package:pharaoh_turbo/pharaoh_turbo.dart';

// import 'definitions.dart';

// Middleware _makeHandler(InstanceMirror parent, MethodMirror methodMirror) {
//   return useRequestHandler((req, res) async {
//     final result = await Future.sync(
//       () => parent.invoke(methodMirror.simpleName, [req, res]),
//     );
//     return result.reflectee;
//   });
// }

// RouteMapping _getMapping(MethodMirror methodMirror) {
//   final routeMappings =
//       methodMirror.metadata.where((e) => e.type.isSubtypeOf(reflectType(RouteMapping)));
//   if (routeMappings.length > 1) {
//     throw PharaohAnnotationError('Methods can have only one RouteMapping',
//         value: routeMappings.toList().sublist(1));
//   }
//   return routeMappings.first.reflectee as RouteMapping;
// }

// ControllerDefinition buildControllerDefinition(BaseController ctrl) {
//   final ctrlMirror = reflect(ctrl);
//   final controllerAnnotations = ctrlMirror.type.metadata;
//   final members = ctrlMirror.type.instanceMembers;

//   /// resolving @Controller annotation on [ctrl]
//   final controllerAnnotation = controllerAnnotations
//       .firstWhereOrNull((e) => e.type.isSubtypeOf(reflectType(Controller)));
//   if (controllerAnnotation == null) {
//     throw PharaohAnnotationError('Class has missing @Controller annotation', value: ctrl);
//   }

//   final List<RouteMethodDefinition> methodDefns = members.values
//       .whereType<MethodMirror>()
//       .where((e) => e.metadata.any((e) => e.type.isSubtypeOf(reflectType(RouteMapping))))
//       .map<RouteMethodDefinition>((e) => RouteMethodDefinition(
//           e.simpleName, _getMapping(e), _makeHandler(ctrlMirror, e)))
//       .toList();

//   final middlewareDefns =
//       ctrlMirror.getField(#middlewares).reflectee as Set<MiddlewareDefinition>;

//   return ControllerDefinition(
//     controllerAnnotation.reflectee,
//     methodDefns: methodDefns,
//     middlewareDefns: middlewareDefns.toList(),
//     instance: ctrlMirror,
//   );
// }
