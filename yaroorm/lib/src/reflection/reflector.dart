import 'package:reflectable/reflectable.dart' as r;

class ReflectableEntity extends r.Reflectable {
  const ReflectableEntity()
      : super(
          r.typeCapability,
          r.invokingCapability,
          r.metadataCapability,
          r.newInstanceCapability,
          r.declarationsCapability,
          r.reflectedTypeCapability,
          r.typeRelationsCapability,
          r.instanceInvokeCapability,
          r.subtypeQuantifyCapability,
          r.typingCapability,
        );
}

const entity = ReflectableEntity();
