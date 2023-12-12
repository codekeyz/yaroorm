import 'package:collection/collection.dart';
import 'package:reflectable/reflectable.dart' as r;

import '../_router/utils.dart';
import '../core.dart';

const unnamedConstructor = '';

const inject = Injectable();

List<X> filteredDeclarationsOf<X extends r.DeclarationMirror>(
  r.ClassMirror cm,
  predicate,
) {
  var result = <X>[];
  cm.declarations.forEach((k, v) {
    if (predicate(v)) {
      result.add(v as X);
    }
  });
  return result;
}

r.ClassMirror reflectType(Type type) => inject.reflectType(type) as r.ClassMirror;

extension ClassMirrorExtensions on r.ClassMirror {
  List<r.VariableMirror> get variables {
    return filteredDeclarationsOf(this, (v) => v is r.VariableMirror);
  }

  List<r.MethodMirror> get getter {
    return filteredDeclarationsOf(this, (v) => v is r.MethodMirror && v.isGetter);
  }

  List<r.MethodMirror> get setters {
    return filteredDeclarationsOf(this, (v) => v is r.MethodMirror && v.isSetter);
  }

  List<r.MethodMirror> get methods {
    return filteredDeclarationsOf(this, (v) => v is r.MethodMirror && v.isRegularMethod);
  }
}

T createNewInstance<T extends Object>(Type classType) {
  final classMirror = reflectType(classType);
  final constructorMethod = classMirror.declarations.entries
      .firstWhereOrNull((e) => e.key == '$classType')
      ?.value as r.MethodMirror?;
  final constructorParameters = constructorMethod?.parameters ?? [];
  if (constructorParameters.isEmpty) {
    return classMirror.newInstance(unnamedConstructor, const []) as T;
  }

  final dependencies = constructorParameters
      .map((e) => e.reflectedType)
      .map((type) => getInstanceFromRegistry(type))
      .toList();

  return classMirror.newInstance(unnamedConstructor, dependencies) as T;
}

Future<dynamic> invokeMethodOnController(
  BaseController instance,
  Symbol method,
) async {
  final mirror = inject.reflect(instance);
  return Future.sync(() => mirror.invoke(method.toString(), []));
}

void ensureControllerHasMethod(Type type, Symbol method) {
  final ctrlMirror = inject.reflectType(type) as r.ClassMirror;
  if (ctrlMirror.superclass?.reflectedType != BaseController) {
    throw ArgumentError('$type must extend BaseController');
  }

  final methods = ctrlMirror.instanceMembers.values.whereType<r.MethodMirror>();
  if (!methods.any((e) => '#${e.simpleName}' == symbolToString(method))) {
    throw ArgumentError('$type does not have method  ${symbolToString(method)}');
  }
}
