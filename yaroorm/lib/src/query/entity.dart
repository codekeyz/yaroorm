import 'package:json_annotation/json_annotation.dart';

import '../reflection/reflector.dart';

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
      throw Exception('Primay Key value must be either `String` or `int` Type');
    }
  }

  dynamic toJson() => PrimaryKey.thisToJson(this);

  static dynamic thisFromJson<T>(data) {
    if (data == null) return PrimaryKey<T>(value: null);
    if (data is int) return PrimaryKey<T>(value: data as T);
    return PrimaryKey<T>(value: '$data' as T);
  }

  static T thisToJson<T>(data) {
    return (data as PrimaryKey).value;
  }
}

class Hello extends Entity {
  @override
  Map<String, dynamic> toJson() => {};
}

@entity
abstract class Entity<T> {
  Entity() {
    if (T == dynamic) {
      throw Exception(
          'Entity Primary Key Data Type is required. Use either `int` or `String`');
    }
  }

  Map<String, dynamic> toJson();

  @JsonKey(fromJson: PrimaryKey.thisFromJson, toJson: PrimaryKey.thisToJson)
  PrimaryKey<T> id = PrimaryKey<T>();

  late DateTime createdAt;

  late DateTime updatedAt;

  bool get enableTimestamps => true;
}
