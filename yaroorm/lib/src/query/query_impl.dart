part of 'query.dart';

enum OrderByDirection { asc, desc }

final class _QueryImpl extends Query {
  _QueryImpl(String tableName) : super(tableName);

  @override
  Query orderByAsc(String field) {
    orderByProps.add((field: field, direction: OrderByDirection.asc));
    return this;
  }

  @override
  Query orderByDesc(String field) {
    orderByProps.add((field: field, direction: OrderByDirection.desc));
    return this;
  }

  @override
  Future insert(Map<String, dynamic> values) {
    return InsertQuery(tableName, values: values).driver(queryDriver).exec();
  }

  @override
  Future<void> insertAll(List<Map<String, dynamic>> values) {
    return InsertManyQuery(tableName, values: values).driver(queryDriver).exec();
  }

  @override
  Future<List<T>> all<T>() async {
    final results = await queryDriver.query(this);
    if (results.isEmpty) return <T>[];
    if (T == dynamic) return results as dynamic;
    return results.map(jsonToEntity<T>).toList();
  }

  @override
  Future<List<T>> take<T>(int limit) async {
    _limit = limit;
    final results = await queryDriver.query(this);
    if (results.isEmpty) return <T>[];
    if (T == dynamic) return results as dynamic;
    return results.map(jsonToEntity<T>).toList();
  }

  @override
  Future<T?> get<T>() async {
    final results = await take<T>(1);
    return results.firstOrNull;
  }

  @override
  WhereClause where<Value>(String field, String condition, [Value? value]) {
    final newClause = WhereClauseImpl(this)..clauseValue = WhereClauseValue.from(field, condition, value);
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereEqual<Value>(String field, Value value) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.EQUAL, value: value));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereNotEqual<Value>(String field, Value value) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_EQUAL, value: value));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> values) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.IN, value: values));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereNotIn<Value>(String field, List<Value> values) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_IN, value: values));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereLike<Value>(String field, String pattern) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.LIKE, value: pattern));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereNotLike<Value>(String field, String pattern) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_LIKE, value: pattern));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereNull(String field) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NULL, value: null));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereNotNull(String field) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereBetween<Value>(String field, List<Value> args) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.BETWEEN, value: args));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause whereNotBetween<Value>(String field, List<Value> args) {
    final newClause = WhereClauseImpl(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_BETWEEN, value: args));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  Future<void> exec() => queryDriver.execute(statement);
}
