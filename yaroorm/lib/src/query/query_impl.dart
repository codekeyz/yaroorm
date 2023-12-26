part of 'query.dart';

enum OrderByDirection { asc, desc }

class QueryImpl<Result> extends Query<Result> {
  QueryImpl(String tableName) : super(tableName);

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
  Future<T> insert<T extends Entity>(T entity) async {
    if (entity.enableTimestamps) entity.createdAt = entity.updatedAt = DateTime.now().toUtc();
    final query = InsertQuery(tableName, values: entity.toJson()..remove('id'));
    final recordId = await queryDriver.insert(query);
    return entity..id = entity.id.withKey(recordId);
  }

  @override
  Future<void> insertMany<T extends Entity>(List<T> entities) async {
    final jsonData = entities.map((e) {
      if (e.enableTimestamps) e.createdAt = e.updatedAt = DateTime.now().toUtc();
      return e.toJson()..remove('id');
    }).toList();
    return queryDriver.insertMany(InsertManyQuery(tableName, values: jsonData));
  }

  @override
  Future<List<Result>> all() async {
    final results = await queryDriver.query(this);
    if (results.isEmpty) return <Result>[];
    if (Result == dynamic) return results as dynamic;
    return results.map(jsonToEntity<Result>).toList();
  }

  @override
  Future<List<Result>> take(int limit) async {
    _limit = limit;
    final results = await queryDriver.query(this);
    if (results.isEmpty) return <Result>[];
    if (Result == dynamic) return results as dynamic;
    return results.map(jsonToEntity<Result>).toList();
  }

  @override
  Future<Result?> get([dynamic id]) async {
    if (id != null) return whereEqual('id', id).findOne();
    final results = await take(1);
    return results.firstOrNull;
  }

  @override
  WhereClause<Result> orWhere<Value>(String field, String condition, [Value? value]) {
    throw StateError('Cannot use `orWhere` directly on a Query you need a WHERE clause first');
  }

  @override
  Query<Result> orWhereFunc(Function(Query<Result> query) builder) {
    if (whereClauses.isEmpty) throw StateError('Cannot use `orWhereFunc` without a where clause');

    final newQuery = QueryImpl<Result>(tableName);
    builder(newQuery);

    final newGroup = WhereClauseImpl(this, operator: LogicalOperator.OR);
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

    final newGroup = WhereClauseImpl(this, operator: LogicalOperator.AND);
    for (final clause in newQuery.whereClauses) {
      newGroup.children.add((clause.operator, clause));
    }

    whereClauses.add(newGroup);

    return this;
  }

  @override
  WhereClause<Result> where<Value>(String field, String condition, [Value? value]) {
    final newClause = WhereClauseImpl<Result>(this)..clauseValue = WhereClauseValue.from(field, condition, value);
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereEqual<Value>(String field, Value value) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.EQUAL, value: value));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotEqual<Value>(String field, Value value) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_EQUAL, value: value));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereIn<Value>(String field, List<Value> values) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.IN, value: values));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotIn<Value>(String field, List<Value> values) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_IN, value: values));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereLike<Value>(String field, String pattern) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.LIKE, value: pattern));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotLike<Value>(String field, String pattern) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_LIKE, value: pattern));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNull(String field) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NULL, value: null));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotNull(String field) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereBetween<Value>(String field, List<Value> values) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.BETWEEN, value: values));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  WhereClause<Result> whereNotBetween<Value>(String field, List<Value> values) {
    final newClause = WhereClauseImpl<Result>(this)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_BETWEEN, value: values));
    whereClauses.add(newClause);
    return newClause;
  }

  @override
  Future<void> exec() => queryDriver.execute(statement);

  @override
  String get statement => queryDriver.serializer.acceptReadQuery(this);
}
