import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';
import 'package:yaroorm/yaroorm.dart';

import '../primitives/where.dart';

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
  EntityMeta get entityMeta {
    if (_entityMetaCache != null) return _entityMetaCache!;
    return _entityMetaCache = getEntityMetaData(Model) ?? EntityMeta(table: getEntityTableName(Model));
  }

  @JsonKey(includeToJson: false, includeFromJson: false)
  DriverContract _driver = DB.defaultDriver;

  /// override this this set the connection for this model
  @JsonKey(includeToJson: false, includeFromJson: false)
  String? get connection => null;

  String? _primaryKeyCache;
  String get _primaryKey {
    if (_primaryKeyCache != null) return _primaryKeyCache!;
    return _primaryKeyCache = getEntityPrimaryKey(Model);
  }

  Model withDriver(DriverContract driver) {
    _driver = driver;
    return this as Model;
  }

  Query<Model> get query => DB.query<Model>().driver(_driver);

  WhereClause<Model> _whereId(Query<Model> _) => _.whereEqual(_primaryKey, id);

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
  Map<String, dynamic> get to_db_data => _entityToDbData(this);

  Map<String, dynamic> _entityToDbData<T extends Entity>(T instance) {
    final entityProperties = getEntityProperties(instance.runtimeType);
    final mappedConverters =
        entityMeta.converters.fold(<Type, EntityTypeConverter>{}, (preV, e) => preV..[e._dartType] = e);

    /// automatically attach DateTime converter if timestamps enabled
    if (entityMeta.timestamps && (mappedConverters.isEmpty || mappedConverters[DateTime] == null)) {
      mappedConverters[DateTime] = _dateTimeConverter;
    }

    /// add boolean converter
    if (mappedConverters.isEmpty || mappedConverters[bool] == null) {
      mappedConverters[bool] = _booleanConverter;
    }

    final instanceMirror = entity.reflect(instance);
    final serializedEntityMap = <String, dynamic>{};
    for (final entry in entityProperties.entries) {
      final value = instanceMirror.invokeGetter(entry.key);
      final typeConverter = mappedConverters[entry.value.type];
      serializedEntityMap[entry.value.dbColumnName] = typeConverter == null ? value : typeConverter.toDbType(value);
    }

    if (serializedEntityMap[_primaryKey] == null) serializedEntityMap.remove(_primaryKey);
    if (!entityMeta.timestamps) {
      serializedEntityMap
        ..remove(entityMeta.createdAtColumn)
        ..remove(entityMeta.updatedAtColumn);
    }

    return serializedEntityMap;
  }
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
    this.converters = const [],
  });
}

@Target({TargetKind.field})
class EntityProperty {
  final String? name;
  const EntityProperty({this.name});
}
