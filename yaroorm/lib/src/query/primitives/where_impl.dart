part of '../query.dart';

class WhereClauseImpl<Result> extends WhereClause<Result> {
  WhereClauseImpl(Query<Result> query, {LogicalOperator operator = LogicalOperator.AND})
      : super(query, operator: operator);

  @override
  WhereClause<Result> whereEqual<Value>(String field, Value value) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.EQUAL, value: value));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotEqual<Value>(String field, Value value) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_EQUAL, value: value));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereIn<Value>(String field, List<Value> values) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.IN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotIn<Value>(String field, List<Value> values) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_IN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereBetween<Value>(String field, List<Value> values) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.BETWEEN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotBetween<Value>(String field, List<Value> values) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_BETWEEN, value: values));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereLike<Value>(String field, String pattern) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.LIKE, value: pattern));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotLike<Value>(String field, String pattern) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_LIKE, value: pattern));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNull(String field) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NULL, value: null));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> whereNotNull(String field) {
    final newChild = WhereClauseImpl(_query)
      ..clauseValue = WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  Future<void> update(Map<String, dynamic> values) {
    return UpdateQuery(_query.tableName, whereClause: this, values: values).driver(_query.queryDriver).exec();
  }

  @override
  Future<void> delete() {
    return DeleteQuery(_query.tableName, whereClause: this).driver(_query.queryDriver).exec();
  }

  @override
  Future<Result?> findOne() => _query.get();

  @override
  Future<List<Result>> findMany() => _query.all();

  @override
  Future<List<Result>> take(int limit) => _query.take(limit);

  @override
  WhereClause<Result> orderByAsc(String field) {
    _query.orderByAsc(field);
    return this;
  }

  @override
  WhereClause<Result> orderByDesc(String field) {
    _query.orderByDesc(field);
    return this;
  }

  @override
  String get statement => _query.statement;

  @override
  WhereClause<Result> where<Value>(String field, String condition, [Value? value]) {
    final newChild = WhereClauseImpl<Result>(_query)..clauseValue = WhereClauseValue.from(field, condition, value);
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> orWhere<Value>(String field, String condition, [Value? value]) {
    final newChild = WhereClauseImpl<Result>(_query, operator: LogicalOperator.OR)
      ..clauseValue = WhereClauseValue.from(field, condition, value);
    _query.whereClauses.add(newChild);
    return newChild;
  }

  @override
  Query<Result> whereFunc(Function(Query<Result> query) builder) {
    return _query.whereFunc(builder);
  }

  @override
  Query<Result> orWhereFunc(Function(Query<Result> query) builder) {
    return _query.orWhereFunc(builder);
  }
}
