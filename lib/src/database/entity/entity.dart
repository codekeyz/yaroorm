// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:meta/meta.dart';

import 'package:meta/meta_meta.dart';

import '../../builder/utils.dart';
import '../../migration.dart';
import '../../query/query.dart';
import '../../reflection.dart';
import '../database.dart';
import '../driver/driver.dart';

part 'converter.dart';
part 'relations.dart';
part 'joins.dart';

abstract class Entity<Parent extends Entity<Parent>> {
  final Map<String, dynamic> _relationsPreloaded = {};

  DriverContract _driver = DB.defaultDriver;

  EntityTypeDefinition<Parent> get _typeDef => Query.getEntity<Parent>();

  String? get connection => null;

  Entity() {
    if (connection != null) _driver = DB.driver(connection!);
  }

  Entity<Parent> withDriver(DriverContract driver) {
    return this.._driver = driver;
  }

  @internal
  Entity<Parent> withRelationsData(Map<String, dynamic> data) {
    _relationsPreloaded
      ..clear()
      ..addAll(data);
    return this;
  }

  @protected
  HasMany<Parent, RelatedModel> hasMany<RelatedModel extends Entity<RelatedModel>>(
    Symbol methodName, {
    Symbol? foreignKey,
  }) {
    final relatedModelTypeData = Query.getEntity<RelatedModel>();
    foreignKey ??= relatedModelTypeData.bindings.entries.firstWhere((e) => e.value.type == Parent).key;
    final referenceField = relatedModelTypeData.columns.firstWhere((e) => e.dartName == foreignKey);

    var relation = _relationsPreloaded[Join._getKey(HasMany<Parent, RelatedModel>, symbolToString(methodName))];

    if (relation is Map) {
      if (relation.isEmpty) {
        relation = <Map<String, dynamic>>[];
      } else {
        relation = [relation.cast<String, dynamic>()];
      }
    }

    return HasMany<Parent, RelatedModel>._(
      referenceField.columnName,
      this as Parent,
      relation,
    );
  }

  @protected
  HasOne<Parent, RelatedModel> hasOne<RelatedModel extends Entity<RelatedModel>>(
    Symbol methodName, {
    Symbol? foreignKey,
  }) {
    final relatedPrimaryKey = Query.getEntity<RelatedModel>().primaryKey.columnName;
    final typeData = Query.getEntity<Parent>();

    foreignKey ??= typeData.bindings.entries.firstWhere((e) => e.value.type == RelatedModel).key;
    final referenceFieldValue = typeData.mirror(this as Parent, foreignKey);

    return HasOne<Parent, RelatedModel>._(
      relatedPrimaryKey,
      referenceFieldValue,
      this as Parent,
      _relationsPreloaded[Join._getKey(HasOne<Parent, RelatedModel>, symbolToString(methodName))],
    );
  }

  @protected
  BelongsTo<Parent, RelatedModel> belongsTo<RelatedModel extends Entity<RelatedModel>>(
    Symbol methodName, {
    Symbol? foreignKey,
  }) {
    final parentFieldName = Query.getEntity<RelatedModel>().primaryKey.columnName;
    foreignKey ??= _typeDef.bindings.entries.firstWhere((e) => e.value.type == RelatedModel).key;
    final referenceFieldValue = _typeDef.mirror(this as Parent, foreignKey);

    return BelongsTo<Parent, RelatedModel>._(
      parentFieldName,
      referenceFieldValue,
      this as Parent,
      _relationsPreloaded[Join._getKey(BelongsTo<Parent, RelatedModel>, symbolToString(methodName))],
    );
  }
}

@Target({TargetKind.classType})
class Table {
  final String? name;
  final List<EntityTypeConverter> converters;

  const Table({
    this.name,
    this.converters = const [],
  });
}

@Target({TargetKind.field})
class TableColumn {
  final String? name;
  final bool nullable;
  final bool unique;

  const TableColumn({this.name, this.nullable = false, this.unique = false});
}

@Target({TargetKind.field})
class PrimaryKey extends TableColumn {
  final bool autoIncrement;
  const PrimaryKey({this.autoIncrement = false, super.name});
}

@Target({TargetKind.field})
class CreatedAtColumn extends TableColumn {
  const CreatedAtColumn() : super(name: 'createdAt', nullable: false);
}

@Target({TargetKind.field})
class UpdatedAtColumn extends TableColumn {
  const UpdatedAtColumn() : super(name: 'updatedAt', nullable: false);
}

/// Use this to reference other entities
class bindTo {
  final Type type;
  final Symbol? on;

  final ForeignKeyAction? onUpdate, onDelete;

  const bindTo(this.type, {this.on, this.onUpdate, this.onDelete});
}

/// A wrapper around arbitrary data [T] to indicate presence or absence
/// explicitly.
///
/// [Value]s are commonly used in companions to distringuish between `null` and
/// absent values.
/// For instance, consider a table with a nullable column with a non-nullable
/// default value:
///
/// ```sql
/// CREATE TABLE orders (
///   priority INT DEFAULT 1 -- may be null if there's no assigned priority
/// );
///
/// For inserts in Dart, there are three different scenarios for the `priority`
/// column:
///
/// - It may be set to `null`, overriding the default value
/// - It may be absent, meaning that the default value should be used
/// - It may be set to an `int` to override the default value
/// ```
///
/// As you can see, a simple `int?` does not provide enough information to
/// distinguish between the three cases. A `null` value could mean that the
/// column is absent, or that it should explicitly be set to `null`.
/// For this reason, drift introduces the [Value] wrapper to make the
/// distinction explicit.
class Value<T> {
  /// Whether this [Value] wrapper contains a present [value] that should be
  /// inserted or updated.
  final bool present;

  final T? _value;

  /// If this value is [present], contains the value to update or insert.
  T get value => _value as T;

  /// Create a (present) value by wrapping the [value] provided.
  const Value(T value)
      : _value = value,
        present = true;

  /// Create an absent value that will not be written into the database, the
  /// default value or null will be used instead.
  const Value.absent()
      : _value = null,
        present = false;

  /// Create a value that is absent if [value] is `null` and [present] if it's
  /// not.
  ///
  /// The functionality is equiavalent to the following:
  /// `x != null ? Value(x) : Value.absent()`.
  ///
  /// This constructor should only be used when [T] is not nullable. If [T] were
  /// nullable, there wouldn't be a clear interpretation for a `null` [value].
  /// See the overall documentation on [Value] for details.
  @Deprecated('Use Value.absentIfNull instead')
  const Value.ofNullable(T? value)
      : assert(
          value != null || null is! T,
          "Value.ofNullable(null) can't be used for a nullable T, since the "
          'null value could be both absent and present.',
        ),
        _value = value,
        present = value != null;

  /// Create a value that is absent if [value] is `null` and [present] if it's
  /// not.
  ///
  /// The functionality is equiavalent to the following:
  /// `x != null ? Value(x) : Value.absent()`.
  const Value.absentIfNull(T? value)
      : _value = value,
        present = value != null;

  @override
  String toString() => present ? 'Value($value)' : 'Value.absent()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Value && present == other.present && _value == other._value;

  @override
  int get hashCode => present.hashCode ^ _value.hashCode;
}
