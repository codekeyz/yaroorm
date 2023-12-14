import '../database/driver/driver.dart';
import 'model.dart';
import 'primitives.dart';

class RecordSelection<Model extends Entity> with TableOperations<Model> {
  final Query _query;

  final String tableName;
  final List<WhereCondition> _whereConditions = [];
  final Set<String> _fieldSelections = {};
  final Set<OrderBy> _orderBy = {};

  RecordSelection._(this._query, this.tableName);

  @override
  RecordSelection<Model> where<Value>(String field, Symbol optor, Value value) {
    final condition = WhereCondition((field: field, optor: optor, value: value));
    _whereConditions.add(condition);
    return this;
  }

  @override
  RecordSelection<Model> select(List<String> fields) {
    _fieldSelections.addAll(fields);
    return this;
  }

  @override
  RecordSelection<Model> orderBy(String field, OrderByDirection direction) {
    _orderBy.add((field: field, order: direction));
    return this;
  }

  @override
  Future<Model> get() async {
    throw Exception();
  }
}

abstract class Query<Model extends Entity> {
  static Query<Model> query<Model extends Entity>(DatabaseDriver driver) =>
      _QueryImpl<Model>(driver);

  RecordSelection<Model> table(String name);

  Future<Model> execute();
}

class _QueryImpl<Model extends Entity> implements Query<Model> {
  final DatabaseDriver _driver;

  _QueryImpl(this._driver);

  @override
  RecordSelection<Model> table(String tableName) => RecordSelection._(this, tableName);

  @override
  Future<Model> execute() async {
    if (!_driver.isOpen) await _driver.connect();
    throw Exception();
  }
}
