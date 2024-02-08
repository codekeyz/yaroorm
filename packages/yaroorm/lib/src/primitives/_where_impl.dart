part of 'where.dart';

class _WhereClauseImpl<Result> extends WhereClause<Result> {
  _WhereClauseImpl(super.query, {super.operator});

  @override
  WhereClause<Result> whereEqual<Value>(String field, Value value) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.EQUAL, value: value));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotEqual<Value>(String field, Value value) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.NOT_EQUAL, value: value));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereIn<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.IN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotIn<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.NOT_IN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereBetween<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.BETWEEN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotBetween<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
          field, (operator: Operator.NOT_BETWEEN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereLike<Value>(String field, String pattern) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.LIKE, value: pattern));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotLike<Value>(String field, String pattern) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
          field, (operator: Operator.NOT_LIKE, value: pattern));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNull(String field) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.NULL, value: null));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotNull(String field) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue =
          WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  Future<void> update(Map<String, dynamic> values) {
    return UpdateQuery(query.tableName, whereClause: this, data: values)
        .driver(query.queryDriver)
        .execute();
  }

  @override
  Future<void> delete() {
    return DeleteQuery(query.tableName, whereClause: this)
        .driver(query.queryDriver)
        .execute();
  }

  @override
  Future<Result?> findOne() => query.get();

  @override
  Future<List<Result>> findMany() => query.all();

  @override
  Future<List<Result>> take(int limit) => query.take(limit);

  @override
  WhereClause<Result> orderByAsc(String field) {
    query.orderByAsc(field);
    return this;
  }

  @override
  WhereClause<Result> orderByDesc(String field) {
    query.orderByDesc(field);
    return this;
  }

  @override
  String get statement => query.statement;

  @override
  WhereClause<Result> where<Value>(String field, String condition,
      [Value? value]) {
    final newChild = _WhereClauseImpl<Result>(query)
      ..clauseValue = WhereClauseValue.from(field, condition, value);
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> orWhere<Value>(String field, String condition,
      [Value? value]) {
    final newChild =
        _WhereClauseImpl<Result>(query, operator: LogicalOperator.OR)
          ..clauseValue = WhereClauseValue.from(field, condition, value);
    query.whereClauses.add(newChild);
    return newChild;
  }

  @override
  Query<Result> whereFunc(Function(Query<Result> query) builder) {
    return query.whereFunc(builder);
  }

  @override
  Query<Result> orWhereFunc(Function(Query<Result> query) builder) {
    return query.orWhereFunc(builder);
  }

  @override
  Future<Result> average(String column) => query.average(column);

  @override
  Future concat(String column) => query.concat(column);

  @override
  Future<Result> count({String field = '*', bool distinct = false}) =>
      query.count(field: field, distinct: distinct);

  @override
  Future<Result> max(String field) => query.max(field);

  @override
  Future<Result> min(String field) => query.min(field);

  @override
  Future<Result> sum(String field) => query.sum(field);

  @override
  Future<Result> total(String field) => query.total(field);
}
