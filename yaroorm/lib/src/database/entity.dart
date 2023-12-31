import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yaroorm/yaroorm.dart';

const entity = ReflectableEntity();

const String entityCreatedAtColumnName = 'created_at';
const String entityUpdatedAtColumnName = 'updated_at';

const String entityToJsonStaticFuncName = 'fromJson';

@entity
abstract class Entity<PkType, Model> {
  Entity() {
    if (PkType == dynamic) {
      throw Exception('Entity Primary Key Data Type is required. Use either `extends Entity<int>` or `Entity<String>`');
    }
  }

  PkType? id;

  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime? createdAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime? updatedAt;

  Query<Model> get _query {
    final connName = connection;
    final query = DB.query<Model>(tableName);
    return connName == null ? query : query.driver(DB.driver(connName));
  }

  WhereClause _whereId(Query _) => _.whereEqual(primaryKey, id);

  @nonVirtual
  Future<void> delete() => _query.delete(_whereId).exec();

  @nonVirtual
  Future<Model> save() async => await _query.insert(this);

  @nonVirtual
  Future<Model?> update(Map<String, dynamic> values) async {
    await _query.update(where: _whereId, values: values).exec();
    return _query.get();
  }

  Map<String, dynamic> toJson();

  bool get enableTimestamps => false;

  String get tableName => typeToTableName(runtimeType);

  /// override this this set the connection for this model
  @JsonKey(includeToJson: false, includeFromJson: false)
  String? connection;

  String get primaryKey => 'id';

  String get createdAtColumn => entityCreatedAtColumnName;

  String get updatedAtColumn => entityUpdatedAtColumnName;

  bool get allowInsertIdAsNull => false;

  Map<String, dynamic> get data {
    final jsonData = toJson();
    if (!allowInsertIdAsNull) jsonData.remove(primaryKey);
    return {...jsonData, if (enableTimestamps) ...timestampData};
  }

  Map<String, dynamic> get timestampData => {
        createdAtColumn: createdAt?.toIso8601String(),
        updatedAtColumn: updatedAt?.toIso8601String(),
      };
}
