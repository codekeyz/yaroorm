import 'package:collection/collection.dart';
import 'package:reflectable/reflectable.dart';

import '../database/entity.dart';
import 'reflector.dart';

class EntityValidationException implements Exception {
  final String message;

  EntityValidationException(this.message);

  @override
  String toString() => 'EntityValidationException: $message';
}

ClassMirror reflectEntity<Model extends Entity>() {
  if (Model == dynamic) {
    throw EntityValidationException(
        'Static Type required for `reflectEntity` call');
  }

  final mirror = (reflectType(Model));
  final fromJson = mirror.staticMembers.entries
      .firstWhereOrNull((d) => d.key == entityToJsonStaticFuncName);
  if (fromJson == null) {
    throw Exception(
        "$Model.$entityToJsonStaticFuncName static method not found.");
  }
  return mirror;
}

Model jsonToEntity<Model extends Entity>(
  Map<String, dynamic> json, {
  ClassMirror? mirror,
}) {
  mirror ??= reflectEntity<Model>();
  return mirror.invoke(entityToJsonStaticFuncName, [json]) as Model;
}
