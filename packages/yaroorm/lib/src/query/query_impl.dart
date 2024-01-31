part of 'query.dart';

enum OrderByDirection { asc, desc }

class QueryImpl<Result> extends Query<Result> {
  QueryImpl(super.tableName);

  @override
  WhereClause<Result> where<Value>(String field, String condition,
      [Value? value]) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue.from(field, condition, value));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  Query<Result> orderByAsc(String field) {
    orderByProps.add((field: field, direction: OrderByDirection.asc));
    return this;
  }

  @override
  Query<Result> orderByDesc(String field) {
    orderByProps.add((field: field, direction: OrderByDirection.desc));
    return this;
  }

  @override
  Future<PrimaryKey> insert<PrimaryKey>(Map<String, dynamic> data) async {
    final recordId =
        await queryDriver.insert(InsertQuery(tableName, data: data));
    return recordId as PrimaryKey;
  }

  @override
  Future<void> insertMany(List<Map<String, dynamic>> values) async {
    return queryDriver.insertMany(InsertManyQuery(tableName, values: values));
  }

  @override
  Future<List<Result>> all() async {
    final results = await queryDriver.query(this);
    if (results.isEmpty) return <Result>[];
    return results.map(_wrapRawResult<Result>).toList();
  }

  @override
  Future<List<Result>> take(int limit) async {
    _limit = limit;
    final results = await queryDriver.query(this);
    if (results.isEmpty) return <Result>[];
    return results.map(_wrapRawResult<Result>).toList();
  }

  @override
  Future<Result?> get([dynamic id]) async {
    if (id != null) {
      return whereEqual(getEntityPrimaryKey(Result), id).findOne();
    }
    return (await take(1)).firstOrNull;
  }

  /// [T] is the expected type passed to [Query] via Query<T>
  T _wrapRawResult<T>(Map<String, dynamic>? result) {
    if (T == dynamic || result == null) return result as dynamic;
    return (serializedPropsToEntity<T>(
      result,
      converters: _queryDriver!.typeconverters,
    )).withDriver(_queryDriver!) as T;
  }

  @override
  WhereClause<Result> orWhere<Value>(String field, String condition,
      [Value? value]) {
    throw StateError(
        'Cannot use `orWhere` directly on a Query you need a WHERE clause first');
  }

  @override
  Query<Result> orWhereFunc(Function(Query<Result> query) builder) {
    if (whereClauses.isEmpty) {
      throw StateError('Cannot use `orWhereFunc` without a where clause');
    }

    final newQuery = QueryImpl<Result>(tableName);
    builder(newQuery);

    final newGroup =
        WhereClause.create<Result>(this, operator: LogicalOperator.OR);
    for (final clause in newQuery.whereClauses) {
      newGroup.children.add((clause.operator, clause));
    }

    whereClauses.add(newGroup);

    return this;
  }

  @override
  Query<Result> whereFunc(Function(Query<Result> query) builder) {
    final newQuery = QueryImpl<Result>(tableName);
    builder(newQuery);

    final newGroup =
        WhereClause.create<Result>(this, operator: LogicalOperator.AND);
    for (final clause in newQuery.whereClauses) {
      newGroup.children.add((clause.operator, clause));
    }

    whereClauses.add(newGroup);

    return this;
  }

  @override
  WhereClause<Result> whereEqual<Value>(String field, Value value) {
    final newClause = WhereClause.create<Result>(this,
        value:
            WhereClauseValue(field, (operator: Operator.EQUAL, value: value)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotEqual<Value>(String field, Value value) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_EQUAL, value: value)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereIn<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(field, (operator: Operator.IN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotIn<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_IN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereLike<Value>(String field, String pattern) {
    final newClause = WhereClause.create<Result>(this,
        value:
            WhereClauseValue(field, (operator: Operator.LIKE, value: pattern)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotLike<Value>(String field, String pattern) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_LIKE, value: pattern)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNull(String field) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(field, (operator: Operator.NULL, value: null)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotNull(String field) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_NULL, value: null)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereBetween<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(
            field, (operator: Operator.BETWEEN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotBetween<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Result>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_BETWEEN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  Future<void> execute() => queryDriver.execute(statement);

  @override
  String get statement => queryDriver.serializer.acceptReadQuery(this);

  @override
  Future<num?> average() => AverageAggregate(queryDriver, tableName).get();

  @override
  Future<num?> count() => CountAggregate(queryDriver, tableName).get();

  @override
  Future<Result?> concat() => ConcatAggregate<Result?>(queryDriver, tableName).get();

  @override
  Future<num?> max() => MaxAggregate(queryDriver, tableName).get();

  @override
  Future<num?> min() => MinAggregate(queryDriver, tableName).get();

  @override
  Future<num?> sum() async => SumAggregate(queryDriver, tableName).get();

  @override
  Future<num?> total() => TotalAggregate(queryDriver, tableName).get();
}
