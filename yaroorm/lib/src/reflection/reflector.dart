import 'package:reflectable/reflectable.dart' as r;

import '../query/entity.dart';

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

r.ClassMirror reflectType(Type type) =>
    entity.reflectType(type) as r.ClassMirror;
