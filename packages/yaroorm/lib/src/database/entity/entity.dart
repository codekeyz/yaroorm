import 'package:recase/recase.dart';

import 'package:yaroorm/yaroorm.dart';
import 'package:meta/meta_meta.dart';

part 'converter.dart';
// part 'relations.dart';

abstract class Entity {
  String get _foreignKeyForModel => '${_type.toString().camelCase}Id';

  Type get _type => runtimeType;

  // HasOne<T> hasOne<T extends Entity>({String? foreignKey}) {
  //   return HasOne<T>(foreignKey ?? _foreignKeyForModel, this);
  // }

  // HasMany<T> hasMany<T extends Entity>({String? foreignKey}) {
  //   return HasMany<T>(foreignKey ?? _foreignKeyForModel, this);
  // }
}

@Target({TargetKind.classType})
class Table {
  final String name;
  final List<EntityTypeConverter>? converters;

  const Table(
    this.name, {
    this.converters,
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
  const PrimaryKey({this.autoIncrement = true});
}

@Target({TargetKind.field})
class CreatedAtColumn extends TableColumn {
  const CreatedAtColumn() : super(name: 'createdAt', nullable: false);
}

@Target({TargetKind.field})
class UpdatedAtColumn extends TableColumn {
  const UpdatedAtColumn() : super(name: 'updatedAt', nullable: false);
}

const primaryKey = PrimaryKey();
const createdAtCol = CreatedAtColumn();
const updatedAtCol = UpdatedAtColumn();
