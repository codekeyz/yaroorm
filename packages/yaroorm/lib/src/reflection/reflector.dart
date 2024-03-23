import 'package:yaroorm/yaroorm.dart';

String getEntityTableName<T extends Entity>() => Query.getEntity<T>().tableName;

String getEntityPrimaryKey<T extends Entity>() =>
    Query.getEntity<T>().primaryKey.columnName;

typedef EntityInstanceReflector<T> = EntityMirror<T> Function(T instance);

typedef EntityInstanceBuilder<T> = T Function(Map<Symbol, dynamic> args);

abstract class EntityMirror<T> {
  final T instance;
  const EntityMirror(this.instance);

  Object? get(Symbol field);
}

class DBEntity<T extends Entity> {
  Type get dartType => T;

  final String tableName;
  final List<DBEntityField> columns;

  final EntityInstanceReflector<T> mirror;
  final EntityInstanceBuilder<T> build;

  final List<EntityTypeConverter> converters;

  final bool timestampsEnabled;

  DBEntityField get primaryKey => columns.firstWhere((e) => e.primaryKey);

  const DBEntity(
    this.tableName, {
    this.columns = const [],
    required this.mirror,
    required this.build,
    this.timestampsEnabled = false,
    this.converters = const [],
  });
}

class DBEntityField {
  /// dart name for property on Entity class
  final Symbol dartName;

  /// Column name in the database
  final String columnName;

  /// Dart primitive type
  final Type type;

  final bool nullable;
  final bool primaryKey;

  const DBEntityField(
    this.columnName,
    this.type,
    this.dartName, {
    required this.nullable,
    this.primaryKey = false,
  });
}
