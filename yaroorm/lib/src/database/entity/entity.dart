import 'package:collection/collection.dart';
import 'package:recase/recase.dart';
import 'package:reflectable/reflectable.dart';

import 'package:yaroorm/yaroorm.dart';
import 'package:meta/meta.dart';
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
    assert(runtimeType == Model, 'Type Mismatch on Entity<$PkType, $Model>. $runtimeType expected');
    if (PkType == dynamic) {
      throw Exception('Entity Primary Key Data Type is required. Use either `extends Entity<int>` or `Entity<String>`');
    }

    if (connection != null) _driver = DB.driver(connection!);
  }

  PkType? id;

  DateTime? createdAt;

  DateTime? updatedAt;

  EntityMeta? _entityMetaCache;

  @visibleForTesting
  EntityMeta get entityMeta => _entityMetaCache ??= getEntityMetaData(Model);

  DriverContract _driver = DB.defaultDriver;

  String? get connection => null;

  Model withDriver(DriverContract driver) {
    _driver = driver;
    return this as Model;
  }

  Query<Model> get query => DB.query<Model>().driver(_driver);

  WhereClause<Model> _whereId(Query<Model> q) => q.whereEqual(entityMeta.primaryKey, id);

  @nonVirtual
  Future<void> delete() => query.delete(_whereId).exec();

  @nonVirtual
  Future<Model> save() async {
    final recordId = await query.insert<PkType>(to_db_data);
    return (this..id = recordId) as Model;
  }

  @nonVirtual
  Future<Model?> update(Map<String, dynamic> values) async {
    if (entityMeta.timestamps && !values.containsKey(entityMeta.updatedAtColumn)) {
      values = Map.from(values);
      values[entityMeta.updatedAtColumn] = DateTime.now().toUtc().toIso8601String();
    }

    await query.update(where: _whereId, values: values).exec();
    return query.get();
  }

  @nonVirtual
  // ignore: non_constant_identifier_names
  Map<String, dynamic> get to_db_data {
    if (entityMeta.timestamps) {
      updatedAt = DateTime.now().toUtc();
      createdAt ??= updatedAt;
    }
    return _serializeEntityProps(this, converters: _driver.typeconverters);
  }

  String get _foreignKeyForModel => '${Model.toString().camelCase}Id';

  HasOne<RelatedModel> hasOne<RelatedModel extends Entity>({String? foreignKey}) =>
      HasOne<RelatedModel>(foreignKey ?? _foreignKeyForModel, this);

  HasMany<RelatedModel> hasMany<RelatedModel extends Entity>({String? foreignKey}) =>
      HasMany<RelatedModel>(foreignKey ?? _foreignKeyForModel, this);
}

@Target({TargetKind.classType})
class EntityMeta {
  final String table;

  final String primaryKey;

  final bool timestamps;

  final String createdAtColumn;
  final String updatedAtColumn;

  final List<EntityTypeConverter>? converters;

  const EntityMeta({
    required this.table,
    this.primaryKey = 'id',
    this.timestamps = false,
    this.createdAtColumn = entityCreatedAtColumnName,
    this.updatedAtColumn = entityUpdatedAtColumnName,
    this.converters,
  });
}

@Target({TargetKind.field})
class EntityProperty {
  final String? name;
  const EntityProperty({this.name});
}
