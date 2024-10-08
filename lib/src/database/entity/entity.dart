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

final class value<T> {
  final T val;
  const value(this.val);
}
