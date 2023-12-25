import 'package:json_annotation/json_annotation.dart';

import '../_reflection/reflector.dart';

const entity = ReflectableEntity();

const String entityCreatedAtColumnName = 'created_at';
const String entityUpdatedAtColumnName = 'updated_at';

const String entityToJsonStaticFuncName = 'fromJson';

class PrimaryKey<T> {
  final T? value;

  T get key => value!;

  PrimaryKey withKey(T value) {
    if (value is int) return PrimaryKey<int>(value: value);
    return PrimaryKey<String>(value: '$value');
  }

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
abstract class Entity<T> {
  Entity() {
    if (T == dynamic) {
      throw Exception('Entity Primary Key Data Type is required. Use either `extends Entity<int>` or `Entity<String>`');
    }
  }

  Map<String, dynamic> toJson();

  @JsonKey(fromJson: PrimaryKey.thisFromJson, toJson: PrimaryKey.thisToJson)
  PrimaryKey<T> id = PrimaryKey<T>();

  @JsonKey(name: entityCreatedAtColumnName)
  late DateTime createdAt;

  @JsonKey(name: entityUpdatedAtColumnName)
  late DateTime updatedAt;

  bool get enableTimestamps => true;
}
