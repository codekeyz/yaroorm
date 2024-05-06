// ignore_for_file: camel_case_types

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import 'package:meta/meta_meta.dart';

import '../../migration.dart';
import '../../query/query.dart';
import '../../reflection.dart';
import '../database.dart';
import '../driver/driver.dart';

part 'converter.dart';
part 'relations.dart';
part 'joins.dart';

abstract class Entity<Parent extends Entity<Parent>> {
  final Map<Type, dynamic> _relationsPreloaded = {};

  DriverContract _driver = DB.defaultDriver;

  DBEntity<Parent>? _typeDataCache;
  DBEntity<Parent> get typeData {
    if (_typeDataCache != null) return _typeDataCache!;
    return _typeDataCache = Query.getEntity<Parent>();
  }

  String? get connection => null;

  Entity() {
    if (connection != null) _driver = DB.driver(connection!);
  }

  Entity<Parent> withDriver(DriverContract driver) {
    return this.._driver = driver;
  }

  @internal
  Entity<Parent> withRelationsData(Map<Type, dynamic> data) {
    _relationsPreloaded
      ..clear()
      ..addAll(data);
    return this;
  }

  @protected
  HasMany<Parent, RelatedModel> hasMany<RelatedModel extends Entity<RelatedModel>>() {
    final relatedModelTypeData = Query.getEntity<RelatedModel>();
    final referenceField = relatedModelTypeData.referencedFields.firstWhere((e) => e.reference.dartType == Parent);

    var relation = _relationsPreloaded[HasMany<Parent, RelatedModel>];

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
  HasOne<Parent, RelatedModel> hasOne<RelatedModel extends Entity<RelatedModel>>() {
    final relatedPrimaryKey = Query.getEntity<RelatedModel>().primaryKey.columnName;
    final typeData = Query.getEntity<Parent>();

    final field = typeData.referencedFields.firstWhere((e) => e.reference.dartType == RelatedModel);
    final referenceFieldValue = typeData.mirror(this as Parent).get(field.dartName);

    return HasOne<Parent, RelatedModel>._(
      relatedPrimaryKey,
      referenceFieldValue,
      this as Parent,
    );
  }

  @protected
  BelongsTo<Parent, RelatedModel> belongsTo<RelatedModel extends Entity<RelatedModel>>() {
    final parentFieldName = Query.getEntity<RelatedModel>().primaryKey.columnName;
    final referenceField = typeData.referencedFields.firstWhere((e) => e.reference.dartType == RelatedModel);
    final referenceFieldValue = typeData.mirror(this as Parent).get(referenceField.dartName);

    return BelongsTo<Parent, RelatedModel>._(
      parentFieldName,
      referenceFieldValue,
      this as Parent,
      _relationsPreloaded[BelongsTo<Parent, RelatedModel>],
    );
  }
}

@Target({TargetKind.classType})
class Table {
  final String name;
  final List<EntityTypeConverter> converters;

  const Table(
    this.name, {
    this.converters = const [],
  });
}

@Target({TargetKind.field})
class TableColumn {
  final String? name;
  final bool nullable;

  const TableColumn({this.name, this.nullable = false});
}

@Target({TargetKind.field})
class PrimaryKey extends TableColumn {
  final bool autoIncrement;
  const PrimaryKey({this.autoIncrement = true, super.name});
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

const primaryKey = PrimaryKey();
const createdAtCol = CreatedAtColumn();
const updatedAtCol = UpdatedAtColumn();

class value<T> {
  final T? val;
  const value(this.val);
}

class NoValue<T> extends value<T> {
  const NoValue() : super(null);
}
