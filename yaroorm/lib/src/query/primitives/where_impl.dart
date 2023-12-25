part of '../query.dart';

class WhereClauseImpl<Result> extends WhereClause<Result> {
  WhereClauseImpl(Query<Result> query, {LogicalOperator operator = LogicalOperator.AND})
      : super(query, operator: operator);

  @override
  WhereClause<Result> where<Value>(String field, String condition, [Value? value]) {
    subparts.add((LogicalOperator.AND, WhereClauseValue.from(field, condition, value)));
    return this;
  }

  @override
  WhereClause<Result> whereEqual<Value>(String field, Value value) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.EQUAL, value: value))));
    return this;
  }

  @override
  WhereClause<Result> whereNotEqual<Value>(String field, Value value) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_EQUAL, value: value))));
    return this;
  }

  @override
  WhereClause<Result> whereIn<Value>(String field, List<Value> values) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.IN, value: values))));
    return this;
  }

  @override
  WhereClause<Result> whereNotIn<Value>(String field, List<Value> values) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_IN, value: values))));
    return this;
  }

  @override
  WhereClause<Result> whereBetween<Value>(String field, List<Value> args) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.BETWEEN, value: args))));
    return this;
  }

  @override
  WhereClause<Result> whereNotBetween<Value>(String field, List<Value> args) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_BETWEEN, value: args))));
    return this;
  }

  @override
  WhereClause<Result> whereLike<Value>(String field, String pattern) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.LIKE, value: pattern))));
    return this;
  }

  @override
  WhereClause<Result> whereNotLike<Value>(String field, String pattern) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_LIKE, value: pattern))));
    return this;
  }

  @override
  WhereClause<Result> whereNull(String field) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NULL, value: null))));
    return this;
  }

  @override
  WhereClause<Result> whereNotNull(String field) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null))));
    return this;
  }

  @override
  Query<Result> whereFunc(Function(WhereClause<Result> $query) function) {
    function(this);
    return _query;
  }

  @override
  Query<Result> orWhereFunc(Function(WhereClause<Result> $query) function) {
    function(_useWhereGroup(LogicalOperator.OR));
    return _query;
  }

  @override
  WhereClause<Result> orWhere<Value>(String field, String condition, [Value? value]) {
    final clauseVal = WhereClauseValue.from(field, condition, value);
    return _useWhereGroup(LogicalOperator.OR, clauseVal);
  }

  WhereClause<Result> _useWhereGroup(LogicalOperator operator, [WhereClauseValue? value]) {
    /// if the current group is of the same operator, just add the new condition to it.
    if (this.operator == operator) {
      if (value == null) return this;
      return this..subparts.add((operator, value));
    }

    /// Create a new group and add the clause value
    final group = WhereClauseImpl(_query, operator: operator)..clauseValue = value;
    _query.whereClauses.add(group);
    return group;
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
    _query.orderByProps.add((field: field, direction: OrderByDirection.asc));
    return this;
  }

  @override
  WhereClause<Result> orderByDesc(String field) {
    _query.orderByProps.add((field: field, direction: OrderByDirection.desc));
    return this;
  }

  @override
  String get statement => _query.statement;
}
