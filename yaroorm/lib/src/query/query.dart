import '../database/driver/driver.dart';
import '../reflection/reflection.dart';
import 'primitives.dart';

export 'primitives.dart';

@entity
abstract class Entity {}

final class RecordQueryInterface<Model extends Entity> implements TableOperations<Model> {
  final String tableName;
  final List<WhereCondition> _whereConditions = [];
  final Set<String> _fieldSelections = {};
  final Set<OrderBy> _orderBy = {};

  DatabaseDriver? _driver;

  RecordQueryInterface(this.tableName, {DatabaseDriver? driver}) : _driver = driver;

  @override
  RecordQueryInterface<Model> where<Value>(String field, Symbol optor, Value value) {
    final condition = WhereCondition((field: field, optor: optor, value: value));
    _whereConditions.add(condition);
    return this;
  }

  @override
  RecordQueryInterface<Model> select(List<String> fields) {
    _fieldSelections.addAll(fields);
    return this;
  }

  @override
  RecordQueryInterface<Model> orderBy(String field, OrderByDirection direction) {
    _orderBy.add((field: field, order: direction));
    return this;
  }

  @override
  Future<Model> get({DatabaseDriver? driver}) async {
    driver ??= _driver;

    throw Exception('Hello World');
  }
}
