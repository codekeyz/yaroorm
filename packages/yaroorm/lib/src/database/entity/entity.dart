import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:recase/recase.dart';

import 'package:meta/meta_meta.dart';

import '../../migration.dart';
import '../../query/query.dart';
import '../../reflection.dart';

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
class Table extends CopyWith {
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
///
/// ignore: camel_case_types
class reference extends TableColumn {
  final Type type;

  final ForeignKeyAction? onUpdate, onDelete;

  const reference(this.type, {super.name, this.onUpdate, this.onDelete});
}

const primaryKey = PrimaryKey();
const createdAtCol = CreatedAtColumn();
const updatedAtCol = UpdatedAtColumn();
