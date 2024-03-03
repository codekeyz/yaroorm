import 'package:collection/collection.dart';
import 'package:recase/recase.dart';
import 'package:reflectable/reflectable.dart';

import 'package:yaroorm/yaroorm.dart';
import 'package:meta/meta_meta.dart';

import '../../primitives/where.dart';
import '../../reflection/util.dart';

part 'converter.dart';
part 'relations.dart';

const entity = ReflectableEntity();

const String entityCreatedAtColumnName = 'createdAt';
const String entityUpdatedAtColumnName = 'updatedAt';

@entity
abstract class Entity<PkType, Model extends Object> {
  Entity() {
    assert(runtimeType == Model,
        'Type Mismatch on Entity<$PkType, $Model>. $runtimeType expected');
    if (PkType == dynamic) {
      throw Exception(
          'Entity Primary Key Data Type is required. Use either `extends Entity<int>` or `Entity<String>`');
    }

    if (connection != null) _driver = DB.driver(connection!);
  }

  PkType? id;

  DateTime? createdAt;

  DateTime? updatedAt;

  Table? _entityMetaCache;

  Table get entityMeta => _entityMetaCache ??= getEntityMetaData(Model);

  DriverContract _driver = DB.defaultDriver;

  String? get connection => null;

  Model withDriver(DriverContract driver) {
    _driver = driver;
    return this as Model;
  }

  Query<Model> get query => DB.query<Model>().driver(_driver);

  WhereClause<Model> _whereId(Query<Model> q) =>
      q.whereEqual(entityMeta.primaryKey, id);

  bool _isLoadedFromDB = false;

  Future<void> delete() => query.delete(_whereId).execute();

  Future<Model> save() async {
    if (_isLoadedFromDB) {
      assert(id != null, 'Id cannot be null when loaded from database');
      if (entityMeta.enableTimestamps) updatedAt = DateTime.now().toUtc();
      await query.update(where: _whereId, values: to_db_data).execute();
      return this as Model;
    }

    final recordId = await query.insert<PkType>(to_db_data);
    return (this
      ..id = recordId
      .._isLoadedFromDB = true) as Model;
  }

  // ignore: non_constant_identifier_names
  Map<String, dynamic> get to_db_data {
    if (entityMeta.enableTimestamps) {
      updatedAt = DateTime.now().toUtc();
      createdAt ??= updatedAt;
    }
    return _serializeEntityProps(this, converters: _driver.typeconverters);
  }

  String get _foreignKeyForModel => '${Model.toString().camelCase}Id';

  HasOne<RelatedModel> hasOne<RelatedModel extends Entity>(
          {String? foreignKey}) =>
      HasOne<RelatedModel>(foreignKey ?? _foreignKeyForModel, this);

  HasMany<RelatedModel> hasMany<RelatedModel extends Entity>(
          {String? foreignKey}) =>
      HasMany<RelatedModel>(foreignKey ?? _foreignKeyForModel, this);
}

@Target({TargetKind.classType})
class Table {
  final String name;

  final String primaryKey;

  final bool enableTimestamps;

  final String createdAtColumn;
  final String updatedAtColumn;

  final List<EntityTypeConverter>? converters;

  const Table({
    required this.name,
    this.primaryKey = 'id',
    this.enableTimestamps = false,
    this.createdAtColumn = entityCreatedAtColumnName,
    this.updatedAtColumn = entityUpdatedAtColumnName,
    this.converters,
  });
}

@Target({TargetKind.field})
class TableColumn {
  final String? name;
  const TableColumn({this.name});
}
