import 'package:reflectable/reflectable.dart' as r;

import '../database/entity.dart';
import 'util.dart';

class ReflectableEntity extends r.Reflectable {
  const ReflectableEntity()
      : super(
          const r.StaticInvokeCapability('fromJson'),
          r.declarationsCapability,
          r.metadataCapability,
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
    throw EntityValidationException('Unable to reflect on $type. Re-run your build command');
  }
}

String getEntityTableName(Type type) {
  final metadata = reflectType(type).metadata.whereType<EntityMeta>().firstOrNull;
  if (metadata != null) return metadata.table;
  return typeToTableName(type);
}

String getEntityPrimaryKey(Type type) {
  final metadata = reflectType(type).metadata.whereType<EntityMeta>().firstOrNull;
  return metadata?.primaryKey ?? 'id';
}
