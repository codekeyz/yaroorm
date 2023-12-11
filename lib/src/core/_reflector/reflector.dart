part of '../core.dart';

const unnamedConstructor = '';

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

enum ResourceType { provider, service, controller }

T createNewInstance<T extends Object>(ResourceType resourceType, Type classType) {
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
