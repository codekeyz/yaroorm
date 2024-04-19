// ignore_for_file: camel_case_types

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

abstract class Entity<Parent extends Entity<Parent>> {
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

  withDriver(DriverContract driver) {
    return this.._driver = driver;
  }

  @protected
  HasMany<Parent, RelatedModel> hasMany<RelatedModel extends Entity<RelatedModel>>([String? foreignKey]) {
    final relatedModelTypeData = Query.getEntity<RelatedModel>();
    final referenceField = relatedModelTypeData.referencedFields.firstWhere((e) => e.reference.dartType == Parent);
    return HasMany<Parent, RelatedModel>._(
      foreignKey ?? referenceField.columnName,
      this as Parent,
    );
  }

  @protected
  BelongsTo<Parent, RelatedModel> belongsTo<RelatedModel extends Entity<RelatedModel>>([String? foreignKey]) {
    final parentFieldName = foreignKey ?? Query.getEntity<RelatedModel>().primaryKey.columnName;
    final referenceField = typeData.referencedFields.firstWhere((e) => e.reference.dartType == RelatedModel);
    final referenceFieldValue = typeData.mirror(this as Parent).get(referenceField.dartName);

    return BelongsTo<Parent, RelatedModel>._(
      parentFieldName,
      this as Parent,
      referenceFieldValue,
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
class reference extends TableColumn {
  final Type type;

  final ForeignKeyAction? onUpdate, onDelete;

  const reference(this.type, {super.name, this.onUpdate, this.onDelete});
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
