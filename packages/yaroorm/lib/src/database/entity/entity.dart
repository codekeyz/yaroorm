import 'package:recase/recase.dart';

import 'package:yaroorm/yaroorm.dart';
import 'package:meta/meta_meta.dart';

part 'converter.dart';
part 'relations.dart';

abstract class Entity<Model extends Object> {
  String get _foreignKeyForModel => '${Model.toString().camelCase}Id';

  HasOne<T> hasOne<T extends Entity>({
    String? foreignKey,
  }) {
    return HasOne<T>(foreignKey ?? _foreignKeyForModel, this);
  }

  HasMany<T> hasMany<T extends Entity>({
    String? foreignKey,
  }) {
    return HasMany<T>(foreignKey ?? _foreignKeyForModel, this);
  }

  final DriverContract _driver = DB.defaultDriver;

  Entity<Model> withDriver(DriverContract driver) {
    return this;
  }

  // ignore: non_constant_identifier_names
  Map<String, dynamic> get to_db_data {
    return _serializeEntityProps(this, converters: _driver.typeconverters);
  }
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
  const PrimaryKey();
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
