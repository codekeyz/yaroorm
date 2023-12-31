import 'package:grammer/grammer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yaroorm/yaroorm.dart';

const entity = ReflectableEntity();

const String entityCreatedAtColumnName = 'created_at';
const String entityUpdatedAtColumnName = 'updated_at';

const String entityToJsonStaticFuncName = 'fromJson';

class PrimaryKey<T> {
  final T? value;

  T get key => value!;

  PrimaryKey<T> withKey(T value) => PrimaryKey<T>(value: value);

  PrimaryKey({this.value}) {
    if (value == null) return;
    if (!(value is String || value is int)) {
      throw Exception('Primary Key value must be either `String` or `int` Type');
    }
  }

  dynamic toJson() => PrimaryKey.thisToJson(this);

  static thisFromJson<T>(data) {
    if (data == null) return PrimaryKey(value: null);
    if (data is int) return PrimaryKey<int>(value: data);
    if (data is String) return PrimaryKey<String>(value: data);
    return PrimaryKey<T>(value: '$data' as T);
  }

  static T thisToJson<T>(data) {
    return (data as PrimaryKey).value;
  }
}

@entity
abstract class Entity<PkType, Model> {
  Entity() {
    if (PkType == dynamic) {
      throw Exception('Entity Primary Key Data Type is required. Use either `extends Entity<int>` or `Entity<String>`');
    }
  }

  Map<String, dynamic> toJson();

  @JsonKey(fromJson: PrimaryKey.thisFromJson, toJson: PrimaryKey.thisToJson)
  PrimaryKey<PkType> id = PrimaryKey<PkType>();

  @JsonKey(name: entityCreatedAtColumnName)
  late DateTime createdAt;

  @JsonKey(name: entityUpdatedAtColumnName)
  late DateTime updatedAt;

  bool get enableTimestamps => true;

  String get tableName => runtimeType.toString().toPlural().first;

  Query<Model> get _query => DB.query<Model>(tableName);

  WhereClause _whereId(Query _) => _.whereEqual('id', id.value);

  @nonVirtual
  Future<void> delete() => _query.delete(_whereId).exec();

  @nonVirtual
  Future<Model> save() async => await _query.insert(this);

  @nonVirtual
  Future<Model?> update(Map<String, dynamic> values) async {
    await _query.update(where: _whereId, values: values).exec();
    return _query.get();
  }
}
