part of '../query.dart';

class WhereClauseImpl extends WhereClause {
  WhereClauseImpl(
    Query query, {
    LogicalOperator operator = LogicalOperator.AND,
  }) : super(query, operator: operator);

  @override
  WhereClauseImpl where<Value>(String field, String condition, [Value? value]) {
    subparts.add((LogicalOperator.AND, WhereClauseValue.from(field, condition, value)));
    return this;
  }

  @override
  WhereClause whereEqual<Value>(String field, Value value) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.EQUAL, value: value))));
    return this;
  }

  @override
  WhereClause whereNotEqual<Value>(String field, Value value) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_EQUAL, value: value))));
    return this;
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> values) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.IN, value: values))));
    return this;
  }

  @override
  WhereClause whereNotIn<Value>(String field, List<Value> values) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_IN, value: values))));
    return this;
  }

  @override
  WhereClause whereBetween<Value>(String field, List<Value> args) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.BETWEEN, value: args))));
    return this;
  }

  @override
  WhereClause whereNotBetween<Value>(String field, List<Value> args) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_BETWEEN, value: args))));
    return this;
  }

  @override
  WhereClause whereLike<Value>(String field, String pattern) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.LIKE, value: pattern))));
    return this;
  }

  @override
  WhereClause whereNotLike<Value>(String field, String pattern) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_LIKE, value: pattern))));
    return this;
  }

  @override
  WhereClause whereNull(String field) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NULL, value: null))));
    return this;
  }

  @override
  WhereClause whereNotNull(String field) {
    subparts.add((LogicalOperator.AND, WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null))));
    return this;
  }

  @override
  Query whereFunc(Function(WhereClauseImpl $query) function) {
    function(this);
    return _query;
  }

  @override
  Query orWhereFunc(Function(WhereClauseImpl $query) function) {
    function(_useWhereGroup(LogicalOperator.OR));
    return _query;
  }

  @override
  WhereClauseImpl orWhere<Value>(String field, String condition, [Value? value]) {
    final clauseVal = WhereClauseValue.from(field, condition, value);
    return _useWhereGroup(LogicalOperator.OR, clauseVal);
  }

  WhereClauseImpl _useWhereGroup(LogicalOperator operator, [WhereClauseValue? value]) {
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
  Future<dynamic> findOne<T extends Entity>() => _query.get<T>();

  @override
  Future<List<dynamic>> findMany<T extends Entity>() => _query.all<T>();

  @override
  Future<List<dynamic>> take<T extends Entity>(int limit) => _query.take<T>(limit);

  @override
  WhereClause orderByAsc(String field) {
    _query.orderByProps.add((field: field, direction: OrderByDirection.asc));
    return this;
  }

  @override
  WhereClause orderByDesc(String field) {
    _query.orderByProps.add((field: field, direction: OrderByDirection.desc));
    return this;
  }

  @override
  String get statement => _query.statement;
}
