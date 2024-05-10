import 'package:collection/collection.dart';

import 'database/entity/entity.dart';
import 'query/query.dart';

String getEntityTableName<T extends Entity<T>>() => Query.getEntity<T>().tableName;

String getEntityPrimaryKey<T extends Entity<T>>() => Query.getEntity<T>().primaryKey.columnName;

typedef EntityInstanceReflector<T> = EntityMirror<T> Function(T instance);

typedef EntityInstanceBuilder<T> = T Function(Map<Symbol, dynamic> args);

abstract class EntityMirror<T> {
  final T instance;
  const EntityMirror(this.instance);

  Object? get(Symbol field);
}

class Binding<Parent extends Entity<Parent>, Related extends Entity<Related>> extends bindTo {
  EntityTypeDefinition<Related> get referenceTypeDef => Query.getEntity<Related>();
  DBEntityField get reference => referenceTypeDef.columns.firstWhere((e) => e.dartName == on!);
  const Binding({required Symbol super.on, super.onDelete, super.onUpdate}) : super(Related);
}

final class EntityTypeDefinition<T extends Entity<T>> {
  Type get dartType => T;

  final String tableName;
  final List<DBEntityField> columns;

  final Map<Symbol, Binding<T, Entity>> bindings;

  final EntityInstanceReflector<T> mirror;
  final EntityInstanceBuilder<T> build;

  final List<EntityTypeConverter> converters;

  final bool timestampsEnabled;

  PrimaryKeyField get primaryKey => columns.firstWhereOrNull((e) => e is PrimaryKeyField) as PrimaryKeyField;

  CreatedAtField? get createdAtField =>
      !timestampsEnabled ? null : columns.firstWhereOrNull((e) => e is CreatedAtField) as CreatedAtField?;

  UpdatedAtField? get updatedAtField =>
      !timestampsEnabled ? null : columns.firstWhereOrNull((e) => e is UpdatedAtField) as UpdatedAtField?;

  Iterable<DBEntityField> get fieldsRequiredForCreate =>
      primaryKey.autoIncrement ? columns.where((e) => e != primaryKey) : columns;

  Iterable<DBEntityField> get editableColumns => columns.where((e) => e != primaryKey);

  const EntityTypeDefinition(
    this.tableName, {
    this.columns = const [],
    this.bindings = const {},
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
  final bool unique;

  bool get isPrimaryKey => false;

  const DBEntityField(
    this.columnName,
    this.type,
    this.dartName, {
    this.nullable = false,
    this.unique = false,
  });

  static PrimaryKeyField primaryKey(
    String columnName,
    Type type,
    Symbol dartName, {
    bool? autoIncrement,
  }) {
    return PrimaryKeyField._(
      columnName,
      type,
      dartName,
      autoIncrement: autoIncrement ?? false,
    );
  }

  static CreatedAtField createdAt(String columnName, Symbol dartName) {
    return CreatedAtField._(columnName, dartName);
  }

  static UpdatedAtField updatedAt(String columnName, Symbol dartName) {
    return UpdatedAtField._(columnName, dartName);
  }
}

final class PrimaryKeyField extends DBEntityField {
  final bool autoIncrement;

  const PrimaryKeyField._(
    super.columnName,
    super.type,
    super.dartName, {
    this.autoIncrement = true,
  }) : super(nullable: false);

  @override
  bool get isPrimaryKey => true;
}

final class CreatedAtField extends DBEntityField {
  const CreatedAtField._(String columnName, Symbol dartName) : super(columnName, DateTime, dartName);
}

final class UpdatedAtField extends DBEntityField {
  const UpdatedAtField._(String columnName, Symbol dartName) : super(columnName, DateTime, dartName);
}
