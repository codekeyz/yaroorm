import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:reflectable/reflectable.dart';

import 'package:yaroorm/yaroorm.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import '../primitives/where.dart';
import '../reflection/util.dart';

part 'type_converter.dart';

const entity = ReflectableEntity();

const String entityCreatedAtColumnName = 'createdAt';
const String entityUpdatedAtColumnName = 'updatedAt';

const String entityFromJsonStaticFuncName = 'fromJson';

@entity
abstract class Entity<PkType, Model> {
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

  Map<String, dynamic> toJson();

  EntityMeta? _entityMetaCache;

  @visibleForTesting
  EntityMeta get entityMeta => _entityMetaCache ??= getEntityMetaData(Model);

  @JsonKey(includeToJson: false, includeFromJson: false)
  DriverContract _driver = DB.defaultDriver;

  /// override this this set the connection for this model
  @JsonKey(includeToJson: false, includeFromJson: false)
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
    if (entityMeta.timestamps) {
      final now = DateTime.now().toUtc();
      createdAt ??= now;
      updatedAt ??= now;
    }
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
  Map<String, dynamic> get to_db_data => _entityToRecord(this);
}

@Target({TargetKind.classType})
class EntityMeta {
  final String table;
  final String primaryKey;
  final bool timestamps;

  final String createdAtColumn;
  final String updatedAtColumn;

  final List<EntityTypeConverter> converters;

  const EntityMeta({
    required this.table,
    this.primaryKey = 'id',
    this.timestamps = false,
    this.createdAtColumn = entityCreatedAtColumnName,
    this.updatedAtColumn = entityUpdatedAtColumnName,
    this.converters = const [_dateTimeConverter, _booleanConverter],
  });
}

@Target({TargetKind.field})
class EntityProperty {
  final String? name;
  const EntityProperty({this.name});
}
