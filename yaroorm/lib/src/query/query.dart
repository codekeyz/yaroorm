import 'package:json_annotation/json_annotation.dart';

import '../database/driver/driver.dart';
import '../reflection/reflector.dart';
import 'primitives.dart';

enum OrderByDirection { asc, desc }

class PrimaryKey<Type> {
  Type? _value;

  Type get value => _value!;

  set val(Type? value) => _setValue(value);

  void _setValue(Type? value) {
    if (value == null) return;
    if (Type is! String || Type is! int) {
      throw Exception('Primay Key value must be either `String` or `int` Type');
    }
    _value = value;
  }

  PrimaryKey({Type? value}) {
    _setValue(value);
  }

  static dynamic fromJson<T>(dynamic data) {
    if (data == null) return PrimaryKey<T>(value: null);
    if (data is int) return PrimaryKey<T>(value: data as T);
    return PrimaryKey<T>(value: '$data' as T);
  }

  static T toJson<T>(T input) => input;
}

@entity
abstract class Entity<T> {
  Map<String, dynamic> toJson();

  @JsonKey(fromJson: PrimaryKey.fromJson, toJson: PrimaryKey.toJson)
  PrimaryKey<T> id = PrimaryKey<T>();

  late DateTime createdAt;

  late DateTime updatedAt;

  bool get enableTimestamps => true;
}

final class EntityTableInterface<Model extends Entity> implements TableOperations<Model> {
  final DatabaseDriver? _driver;

  final String tableName;
  final Set<String> fieldSelections = {};
  final Set<OrderBy> orderByProps = {};

  WhereClause? whereClause;

  EntityTableInterface(this.tableName, {DatabaseDriver? driver}) : _driver = driver;

  @override
  Future<Model> get({DatabaseDriver? driver}) async {
    driver ??= _driver;
    if (driver == null) {
      throw Exception('No Database driver provided');
    }

    final result = await driver.query(this);

    throw Exception('Hello World');
  }

  String get rawQuery {
    if (_driver == null) {
      throw Exception('Cannot resolve rawQuery. No driver provided');
    }
    return _driver!.querySerializer.acceptQuery(this);
  }

  @override
  WhereClause<Model> where<Value>(String field, String condition, Value value) {
    if (whereClause != null) throw Exception('Only one where clause is supported');
    return whereClause = WhereClause<Model>(
      (field: field, condition: condition, value: value),
      this,
    );
  }

  @override
  Future<Model> insert(Model model) async {
    if (model.enableTimestamps) {
      model.createdAt = model.updatedAt = DateTime.now().toUtc();
    }

    final result = await _driver!.insert(tableName, model.toJson()..remove('id'));
    print(result);

    return model;
  }

  @override
  Future<void> insertMany(List<Model> entity) async {}
}
