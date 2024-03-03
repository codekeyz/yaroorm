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
          r.typeAnnotationQuantifyCapability,
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

String getEntityTableName(Type type) => getEntityMetaData(type).name;

String getEntityPrimaryKey(Type type) => getEntityMetaData(type).primaryKey;

Table getEntityMetaData(Type type) {
  return reflectType(type).metadata.whereType<Table>().firstOrNull ??
      Table(name: type.toString().snakeCase.toPlural().first);
}

class EntityPropertyData {
  final bool primaryKey;

  // This is the name of property on the Dart Class
  final String dartName;

  // This is the name of the property in database table
  final String dbColumnName;

  final Type type;
  final bool nullable;

  const EntityPropertyData(
    this.dartName,
    this.dbColumnName,
    this.type, {
    this.nullable = false,
    this.primaryKey = false,
  });
}

Map<String, EntityPropertyData> getEntityProperties(
  Type type, {
  ClassMirror? classMirror,
}) {
  classMirror ??= reflectType(type);

  final metadata = classMirror.metadata.whereType<Table>().firstOrNull;

  final typeProps = classMirror.declarations.values
      .whereType<VariableMirror>()
      .fold<Map<String, EntityPropertyData>>({}, (prev, curr) {
    final propertyMeta = curr.metadata.whereType<TableColumn>().firstOrNull;

    return prev
      ..[curr.simpleName] = EntityPropertyData(
        curr.simpleName,
        propertyMeta?.name ?? curr.simpleName,
        curr.reflectedType,
        nullable: curr.type.isNullable,
      );
  });

  final primaryKeyProp = metadata?.primaryKey ?? 'id';
  typeProps['id'] =
      EntityPropertyData('id', primaryKeyProp, int, primaryKey: true);

  if (metadata == null || !metadata.enableTimestamps) return typeProps;

  typeProps[metadata.createdAtColumn] ??=
      EntityPropertyData('createdAt', metadata.createdAtColumn, DateTime);

  typeProps[metadata.updatedAtColumn] ??=
      EntityPropertyData('updatedAt', metadata.updatedAtColumn, DateTime);

  return typeProps;
}
