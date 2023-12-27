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

ClassMirror reflectEntity<Model>() {
  late ClassMirror mirror;

  try {
    mirror = (reflectType(Model));
    final fromJson = mirror.staticMembers.entries.firstWhereOrNull((d) => d.key == entityToJsonStaticFuncName);
    if (fromJson == null) {
      throw EntityValidationException("$Model.$entityToJsonStaticFuncName static method not found.");
    }
  } catch (e) {
    if (e is EntityValidationException) rethrow;
    throw EntityValidationException("Either $Model is not a subtype of Entity or re-run your build_runner command");
  }

  return mirror;
}

Model jsonToEntity<Model>(
  Map<String, dynamic> json, {
  ClassMirror? mirror,
}) {
  mirror ??= reflectEntity<Model>();
  return mirror.invoke(entityToJsonStaticFuncName, [json]) as Model;
}
