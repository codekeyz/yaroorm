part of '../access.dart';

enum OrderByDirection { asc, desc }

final class _QueryImpl extends Query {
  _QueryImpl(String tableName, DatabaseDriver driver)
      : super(tableName, driver);

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
  Future<T> insert<T extends Entity>(T model) async {
    if (model.enableTimestamps) {
      model.createdAt = model.updatedAt = DateTime.now().toUtc();
    }
    final dataMap = model.toJson()..remove('id');
    final recordId = await driver.insert(tableName, dataMap);
    return model..id = model.id.withKey(recordId);
  }

  @override
  Future<void> _update(WhereClause where, Map<String, dynamic> values) async {
    final query =
        UpdateQuery(tableName, driver, whereClause: where, values: values);
    await driver.update(query);
  }

  @override
  Future<void> _delete(WhereClause where) async {
    final query = DeleteQuery(tableName, driver, whereClause: where);
    await driver.delete(query);
  }

  @override
  Future<List<T>> all<T>() async {
    final results = await driver.query(this);
    if (results.isEmpty) return <T>[];
    if (T == dynamic) return results as dynamic;
    return results.map(jsonToEntity<T>).toList();
  }

  @override
  Future<List<T>> take<T>(int limit) async {
    _limit = limit;
    final results = await driver.query(this);
    if (results.isEmpty) return <T>[];
    if (T == dynamic) return results as dynamic;
    return results.map(jsonToEntity<T>).toList();
  }

  @override
  Future<T?> first<T>() async {
    final results = await take<T>(1);
    return results.firstOrNull;
  }

  @override
  WhereClause where<Value>(String field, String condition, [Value? value]) {
    return _whereClause = WhereClauseImpl(
      this,
      WhereClauseValue.from(field, condition, value),
    );
  }

  @override
  WhereClause whereBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  ) {
    return _whereClause =
        WhereClause.fromOperator(field, Operator.BETWEEN, args, query: this);
  }

  @override
  WhereClause whereNotBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  ) {
    return _whereClause = WhereClause.fromOperator(
        field, Operator.NOT_BETWEEN, args,
        query: this);
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> values) {
    return _whereClause =
        WhereClause.fromOperator(field, Operator.IN, values, query: this);
  }

  @override
  WhereClause whereNotIn<Value>(String field, List<Value> values) {
    return _whereClause =
        WhereClause.fromOperator(field, Operator.NOT_IN, values, query: this);
  }

  @override
  WhereClause whereLike<Value>(String field, String pattern) {
    return _whereClause =
        WhereClause.fromOperator(field, Operator.LIKE, pattern, query: this);
  }

  @override
  WhereClause whereNotLike<Value>(String field, String pattern) {
    return _whereClause = WhereClause.fromOperator(
        field, Operator.NOT_LIKE, pattern,
        query: this);
  }

  @override
  WhereClause whereNull(String field) {
    return _whereClause =
        WhereClause.fromOperator(field, Operator.NULL, null, query: this);
  }

  @override
  WhereClause whereNotNull(String field) {
    return _whereClause =
        WhereClause.fromOperator(field, Operator.NOT_NULL, null, query: this);
  }
}
