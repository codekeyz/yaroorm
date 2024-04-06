part of 'query.dart';

enum OrderByDirection { asc, desc }

class QueryImpl<Model extends Entity> extends Query<Model> {
  QueryImpl(super.tableName);

  @override
  WhereClause<Model> where<Value>(
    String field,
    String condition, [
    Value? value,
  ]) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue.from(field, condition, value));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  Query<Model> orderByAsc(String field) {
    orderByProps.add((field: field, direction: OrderByDirection.asc));
    return this;
  }

  @override
  Query<Model> orderByDesc(String field) {
    orderByProps.add((field: field, direction: OrderByDirection.desc));
    return this;
  }

  @override
  Future<Model> insert(Map<Symbol, dynamic> data) async {
    final dataToDbD = conformToDbTypes<Model>(data, converters);
    final recordId =
        await runner.insert(InsertQuery(tableName, data: dataToDbD));
    return (await get(recordId))!;
  }

  @override
  Future<void> insertMany(List<Map<String, dynamic>> values) async {
    throw Exception();
  }

  @override
  Future<List<Model>> all({int? limit}) async {
    final results = await runner.query(this.._limit = limit);
    if (results.isEmpty) return <Model>[];
    return results.map(_wrapRawResult).toList();
  }

  @override
  Future<List<Model>> take(int limit) async {
    final results = await runner.query(this.._limit = limit);
    if (results.isEmpty) return <Model>[];
    return results.map(_wrapRawResult).toList();
  }

  @override
  Future<Model?> get([dynamic id]) async {
    if (id != null) {
      return equal(getEntityPrimaryKey<Model>(), id).findOne();
    }
    return (await take(1)).firstOrNull;
  }

  /// [T] is the expected type passed to [Query] via Query<T>
  Model _wrapRawResult(Map<String, dynamic>? result) {
    if (result == null) return result as dynamic;
    return serializedPropsToEntity<Model>(
      result,
      entity,
      converters,
    );
  }

  @override
  WhereClause<Model> orWhere<Value>(String field, String condition,
      [Value? value]) {
    throw StateError(
        'Cannot use `orWhere` directly on a Query you need a WHERE clause first');
  }

  @override
  Query<Model> orWhereFunc(Function(Query<Model> query) builder) {
    if (whereClauses.isEmpty) {
      throw StateError('Cannot use `orWhereFunc` without a where clause');
    }

    final newQuery = QueryImpl<Model>(tableName);
    builder(newQuery);

    final newGroup =
        WhereClause.create<Model>(this, operator: LogicalOperator.OR);
    for (final clause in newQuery.whereClauses) {
      newGroup.children.add((clause.operator, clause));
    }

    whereClauses.add(newGroup);

    return this;
  }

  @override
  Query<Model> whereFunc(Function(Query<Model> query) builder) {
    final newQuery = QueryImpl<Model>(tableName);
    builder(newQuery);

    final newGroup =
        WhereClause.create<Model>(this, operator: LogicalOperator.AND);
    for (final clause in newQuery.whereClauses) {
      newGroup.children.add((clause.operator, clause));
    }

    whereClauses.add(newGroup);

    return this;
  }

  @override
  WhereClause<Model> equal<Value>(String field, Value value) {
    final newClause = WhereClause.create<Model>(this,
        value:
            WhereClauseValue(field, (operator: Operator.EQUAL, value: value)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> notEqual<Value>(String field, Value value) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_EQUAL, value: value)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isIn<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(field, (operator: Operator.IN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isNotIn<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_IN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isLike<Value>(String field, String pattern) {
    final newClause = WhereClause.create<Model>(this,
        value:
            WhereClauseValue(field, (operator: Operator.LIKE, value: pattern)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isNotLike<Value>(String field, String pattern) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_LIKE, value: pattern)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isNull(String field) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(field, (operator: Operator.NULL, value: null)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isNotNull(String field) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_NULL, value: null)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isBetween<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(
            field, (operator: Operator.BETWEEN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Model> isNotBetween<Value>(String field, List<Value> values) {
    final newClause = WhereClause.create<Model>(this,
        value: WhereClauseValue(
            field, (operator: Operator.NOT_BETWEEN, value: values)));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  Future<void> execute() => runner.execute(statement);

  @override
  String get statement => runner.serializer.acceptReadQuery(this);

  @override
  Future<num> average(String field) {
    return AverageAggregate(this, field).get();
  }

  @override
  Future<int> count({String? field, bool distinct = false}) {
    return CountAggregate(this, field).get();
  }

  @override
  Future<String> groupConcat(String field, String separator) {
    return GroupConcatAggregate(this, field, separator).get();
  }

  @override
  Future<num> max(String field) => MaxAggregate(this, field).get();

  @override
  Future<num> min(String field) => MinAggregate(this, field).get();

  @override
  Future<num> sum(String field) => SumAggregate(this, field).get();
}
