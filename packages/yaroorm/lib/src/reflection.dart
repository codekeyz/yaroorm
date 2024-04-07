
import 'package:yaroorm/src/utils.dart';

import 'database/entity/entity.dart';
import 'query/query.dart';

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

final class DBEntity<T extends Entity> {
  Type get dartType => T;

  final String tableName;
  final List<DBEntityField> columns;

  final EntityInstanceReflector<T> mirror;
  final EntityInstanceBuilder<T> build;

  final List<EntityTypeConverter> converters;

  final bool timestampsEnabled;

  PrimaryKeyField get primaryKey => columns.firstWhereOrNull((e) => e is PrimaryKeyField) as PrimaryKeyField;

  CreatedAtField? get createdAtField => !timestampsEnabled
      ? null
      : columns.firstWhereOrNull((e) => e is CreatedAtField) as CreatedAtField?;

  UpdatedAtField? get updatedAtField => !timestampsEnabled
      ? null
      : columns.firstWhereOrNull((e) => e is UpdatedAtField) as UpdatedAtField?;

  List<DBEntityField> get editableColumns =>
      columns.where((e) => e != primaryKey).toList();

  const DBEntity(
    this.tableName, {
    this.columns = const [],
    required this.mirror,
    required this.build,
    this.timestampsEnabled = false,
    this.converters = const [],
  });
}




final class DBEntityField {
  /// dart name for property on Entity class
  final Symbol dartName;

  /// Column name in the database
  final String columnName;

  /// Dart primitive type
  final Type type;

  final bool nullable;

  bool get primaryKey => false;

  const DBEntityField(this.columnName, this.type, this.dartName,
      {this.nullable = false});
}

final class PrimaryKeyField extends DBEntityField {
  final bool autoIncrement;

  const PrimaryKeyField(
    super.columnName,
    super.type,
    super.dartName, {
    this.autoIncrement = true,
  }) : super(nullable: false);

  @override
  bool get primaryKey => true;
}

final class CreatedAtField extends DBEntityField {
  const CreatedAtField(String columnName, Symbol dartName)
      : super(columnName, DateTime, dartName);
}

final class UpdatedAtField extends DBEntityField {
  const UpdatedAtField(String columnName, Symbol dartName)
      : super(columnName, DateTime, dartName);
}
