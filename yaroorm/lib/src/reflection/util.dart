import 'package:reflectable/reflectable.dart';
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
  } catch (e) {
    throw EntityValidationException("Either $Model is not a subtype of Entity or re-run your build_runner command");
  }
  return mirror;
}
