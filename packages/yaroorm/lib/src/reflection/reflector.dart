import 'package:collection/collection.dart';
import 'package:grammer/grammer.dart';
import 'package:recase/recase.dart';
import 'package:reflectable/mirrors.dart';
import 'package:reflectable/reflectable.dart' as r;

import '../database/entity/entity.dart';
import 'util.dart';

class ReflectableEntity extends r.Reflectable {
  const ReflectableEntity()
      : super(
          r.declarationsCapability,
          r.metadataCapability,
          r.invokingCapability,
          r.newInstanceCapability,

          ///
          r.typeCapability,
          r.reflectedTypeCapability,
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

String getEntityTableName(Type type) => getEntityMetaData(type).table;

String getEntityPrimaryKey(Type type) => getEntityMetaData(type).primaryKey;

EntityMeta getEntityMetaData(Type type) {
  return reflectType(type).metadata.whereType<EntityMeta>().firstOrNull ??
      EntityMeta(table: type.toString().snakeCase.toPlural().first);
}

class EntityPropertyData {
  final String dartName;
  final String dbColumnName;
  final Type type;

  const EntityPropertyData(this.dartName, this.dbColumnName, this.type);
}

Map<String, EntityPropertyData> getEntityProperties(Type type,
    {ClassMirror? classMirror}) {
  classMirror ??= reflectType(type);

  final metadata = classMirror.metadata.whereType<EntityMeta>().firstOrNull;

  final typeProps = classMirror.declarations.values
      .whereType<VariableMirror>()
      .fold<Map<String, EntityPropertyData>>({}, (prev, curr) {
    final propertyMeta = curr.metadata.whereType<EntityProperty>().firstOrNull;
    return prev
      ..[curr.simpleName] = EntityPropertyData(curr.simpleName,
          propertyMeta?.name ?? curr.simpleName, curr.reflectedType);
  });
  if (metadata == null || !metadata.timestamps) return typeProps;

  typeProps[metadata.createdAtColumn] ??=
      EntityPropertyData('createdAt', metadata.createdAtColumn, DateTime);

  typeProps[metadata.updatedAtColumn] ??=
      EntityPropertyData('updatedAt', metadata.updatedAtColumn, DateTime);

  return typeProps;
}
