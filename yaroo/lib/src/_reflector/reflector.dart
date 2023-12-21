import 'package:collection/collection.dart';
import 'package:reflectable/reflectable.dart' as r;

import '../../../http/http.dart';
import '../_container/container.dart';
import '../_router/definition.dart';
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
  final constructorMethod =
      classMirror.declarations.entries.firstWhereOrNull((e) => e.key == '$classType')?.value as r.MethodMirror?;
  final constructorParameters = constructorMethod?.parameters ?? [];
  if (constructorParameters.isEmpty) {
    return classMirror.newInstance(unnamedConstructor, const []) as T;
  }

  final dependencies =
      constructorParameters.map((e) => e.reflectedType).map((type) => instanceFromRegistry(type: type)).toList();

  return classMirror.newInstance(unnamedConstructor, dependencies) as T;
}

ControllerMethod parseControllerMethod(ControllerMethodDefinition defn) {
  final type = defn.$1;
  final method = defn.$2;

  final ctrlMirror = inject.reflectType(type) as r.ClassMirror;
  if (ctrlMirror.superclass?.reflectedType != ApplicationController) {
    throw ArgumentError('$type must extend BaseController');
  }

  final methods = ctrlMirror.instanceMembers.values.whereType<r.MethodMirror>();
  final actualMethod = methods.firstWhereOrNull((e) => e.simpleName == symbolToString(method));
  if (actualMethod == null) {
    throw ArgumentError('$type does not have method  #${symbolToString(method)}');
  }

  if (actualMethod.parameters.isNotEmpty) {
    throw ArgumentError.value('$type.${actualMethod.simpleName}', null, 'Controller methods cannot have parameters');
  }

  return ControllerMethod(defn);
}
