import '../database/driver/driver.dart';
import '../reflection/entity_helpers.dart';
import 'entity.dart';

export 'entity.dart';

part 'operations.dart';
part 'primitives/where.dart';

enum OrderByDirection { asc, desc }

final class EntityTableInterface<Model extends Entity>
    implements EntityOperations<Model> {
  final DatabaseDriver? _driver;

  final String tableName;
  final Set<String> fieldSelections = {};
  final Set<OrderBy> orderByProps = {};

  WhereClause? _whereClause;
  int? _limit;

  WhereClause? get whereClause => _whereClause;

  int? get limitValue => _limit;

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
  Future<List<Model>> all() async {
    final results = await _driver!.query(this);
    if (results.isEmpty) return <Model>[];
    return results.map<Model>(jsonToEntity<Model>).toList();
  }

  @override
  Future<List<Model>> limit(int limit) async {
    _limit = limit;
    final results = await _driver!.query(this);
    if (results.isEmpty) return <Model>[];
    return results.map<Model>(jsonToEntity<Model>).toList();
  }

  @override
  EntityTableInterface<Model> orderBy(
    String field,
    OrderByDirection direction,
  ) {
    orderByProps.add((field: field, direction: direction));
    return this;
  }

  @override
  Future<Model?> findOne() async {
    final results = await this.limit(1);
    return results.firstOrNull;
  }

  @override
  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  ) {
    return _whereClause = WhereClause<Model>(
      (field: field, condition: condition, value: value),
      this,
    );
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
}
