import 'package:reflectable/reflectable.dart' as r;

import '../database/entity.dart';
import 'entity_helpers.dart';

class ReflectableEntity extends r.Reflectable {
  const ReflectableEntity()
      : super(
          const r.StaticInvokeCapability('fromJson'),
          r.declarationsCapability,
          r.newInstanceCapability,

          ///
          r.typeCapability,
          r.subtypeQuantifyCapability,
        );
}

r.ClassMirror reflectType(Type type) {
  try {
    return entity.reflectType(type) as r.ClassMirror;
  } catch (e) {
    throw EntityValidationException(
        'Unable to reflect on $type. Re-run your build command');
  }
}
