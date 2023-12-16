import 'package:collection/collection.dart';

import '../database/driver/driver.dart';
import '../reflection/reflector.dart';
import 'entity.dart';
import 'primitives.dart';

export 'entity.dart';

enum OrderByDirection { asc, desc }

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

    throw Exception('Hello World');
  }

  String get sqlScript {
    final driver = _driver;
    if (driver == null) {
      throw Exception('Cannot resolve rawQuery. No driver provided');
    }
    return driver.querySerializer.acceptQuery(this);
  }

  @override
  WhereClause<Model> where<Value>(String field, String condition, Value value) {
    if (whereClause != null) {
      throw Exception('Only one where clause is supported');
    }
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
    final recordId = await _driver!.insert(tableName, model.toJson()..remove('id'));
    return model..id = model.id.withKey(recordId);
  }

  @override
  Future<List<Model>> all() async {
    /// TODO: move this into a re-usable field later
    final mirror = (reflectType(Model));
    final fromJson =
        mirror.staticMembers.entries.firstWhereOrNull((d) => d.key == 'fromJson');
    if (fromJson == null) {
      throw Exception("$Model.fromJson static method not found.");
    }

    final result = await _driver!.query(this);
    if (result.isEmpty) return <Model>[];
    return result
        .map<Model>((data) => mirror.invoke('fromJson', [data]) as Model)
        .toList();
  }
}
