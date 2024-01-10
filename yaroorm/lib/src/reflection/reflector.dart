import 'package:collection/collection.dart';
import 'package:grammer/grammer.dart';
import 'package:recase/recase.dart';
import 'package:reflectable/mirrors.dart';
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
          r.reflectedTypeCapability,
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

String getEntityTableName(Type type) => getEntityMetaData(type)?.table ?? type.toString().snakeCase.toPlural().first;

String getEntityPrimaryKey(Type type) => getEntityMetaData(type)?.primaryKey ?? 'id';

EntityMeta? getEntityMetaData(Type type) => reflectType(type).metadata.whereType<EntityMeta>().firstOrNull;

Map<String, Type> getEntityProperties(Type type) {
  final classMirror = reflectType(type);
  final metadata = classMirror.metadata.whereType<EntityMeta>().firstOrNull;

  final methodMirror = classMirror.declarations.values
      .firstWhere((e) => e is MethodMirror && e.simpleName == type.toString()) as MethodMirror;

  final typeProps =
      methodMirror.parameters.fold<Map<String, Type>>({}, (prev, curr) => prev..[curr.simpleName] = curr.reflectedType);
  if (metadata == null || !metadata.timestamps) return typeProps;

  typeProps[metadata.createdAtColumn] = DateTime;
  typeProps[metadata.updatedAtColumn] = DateTime;

  return typeProps;
}
