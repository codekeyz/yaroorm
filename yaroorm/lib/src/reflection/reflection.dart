import 'package:reflectable/reflectable.dart' as r;

class ReflectableEntity extends r.Reflectable {
  const ReflectableEntity()
      : super(
          r.newInstanceCapability,
          r.declarationsCapability,
          r.reflectedTypeCapability,
          r.typeRelationsCapability,
          r.instanceInvokeCapability,
        );
}

const entity = ReflectableEntity();

class ReflectableMigration extends r.Reflectable {
  const ReflectableMigration()
      : super(
          r.newInstanceCapability,
          r.reflectedTypeCapability,
          r.typeRelationsCapability,
          r.instanceInvokeCapability,
        );
}

const migration = ReflectableMigration();
