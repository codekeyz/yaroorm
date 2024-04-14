import 'package:yaroorm/src/utils.dart';

import 'database/entity/entity.dart';
import 'migration.dart';
import 'query/query.dart';

String getEntityTableName<T extends Entity>() => Query.getEntity<T>().tableName;

String getEntityPrimaryKey<T extends Entity>() => Query.getEntity<T>().primaryKey.columnName;

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

  CreatedAtField? get createdAtField =>
      !timestampsEnabled ? null : columns.firstWhereOrNull((e) => e is CreatedAtField) as CreatedAtField?;

  UpdatedAtField? get updatedAtField =>
      !timestampsEnabled ? null : columns.firstWhereOrNull((e) => e is UpdatedAtField) as UpdatedAtField?;

  Iterable<ReferencedField> get referencedFields => columns.whereType<ReferencedField>();

  Iterable<DBEntityField> get editableColumns => columns.where((e) => e != primaryKey);

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

  bool get isPrimaryKey => false;

  const DBEntityField(
    this.columnName,
    this.type,
    this.dartName, {
    this.nullable = false,
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

  static ReferencedField<T> referenced<T extends Entity>(
    String columnName,
    Symbol dartName, {
    bool nullable = false,
    ForeignKeyAction? onUpdate,
    ForeignKeyAction? onDelete,
  }) {
    return ReferencedField<T>._(columnName, dartName, nullable: nullable, onUpdate: onUpdate, onDelete: onDelete);
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

final class ReferencedField<T extends Entity> implements DBEntityField {
  final DBEntity<T> reference;
  final String _columnName;
  final Symbol _dartName;
  final bool _nullable;

  final ForeignKeyAction? onUpdate, onDelete;

  ReferencedField._(
    this._columnName,
    this._dartName, {
    bool nullable = false,
    this.onDelete,
    this.onUpdate,
  })  : _nullable = nullable,
        reference = Query.getEntity<T>();

  @override
  String get columnName => _columnName;

  @override
  Symbol get dartName => _dartName;

  @override
  bool get isPrimaryKey => false;

  @override
  bool get nullable => _nullable;

  @override
  Type get type => reference.primaryKey.type;
}
