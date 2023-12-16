import '../database/driver/driver.dart';
import '../reflection/entity_helpers.dart';
import 'entity.dart';
import 'primitives.dart';

export 'entity.dart';

enum OrderByDirection { asc, desc }

final class EntityTableInterface<Model extends Entity>
    implements EntityOperations<Model> {
  final DatabaseDriver? _driver;

  final String tableName;
  final Set<String> fieldSelections = {};
  final Set<OrderBy> orderByProps = {};

  WhereClause? whereClause;

  EntityTableInterface(this.tableName, {DatabaseDriver? driver})
      : _driver = driver;

  String get sqlScript {
    final driver = _driver;
    if (driver == null) {
      throw Exception('Cannot resolve rawQuery. No driver provided');
    }
    return driver.querySerializer.acceptQuery(this);
  }

  @override
  Future<Model> insert(Model model) async {
    if (model.enableTimestamps) {
      model.createdAt = model.updatedAt = DateTime.now().toUtc();
    }
    final recordId =
        await _driver!.insert(tableName, model.toJson()..remove('id'));
    return model..id = model.id.withKey(recordId);
  }

  @override
  Future<List<Model>> all() async {
    final result = await _driver!.query(this);
    if (result.isEmpty) return <Model>[];
    return result.map<Model>(jsonToEntity<Model>).toList();
  }

  @override
  Future<Model?> findOne() async {
    final result = await _driver!.query(this);
    if (result.isEmpty) return null;
    return jsonToEntity<Model>(result.first);
  }

  @override
  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  ) {
    return whereClause = WhereClause<Model>(
      (field: field, condition: condition, value: value),
      this,
    );
  }
}
