part of 'where.dart';

class _WhereClauseImpl<Result extends Entity> extends WhereClause<Result> {
  _WhereClauseImpl(super.query, {super.operator});

  @override
  WhereClause<Result> equal<Value>(String field, Value value) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.EQUAL, value: value),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> notEqual<Value>(String field, Value value) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.NOT_EQUAL, value: value),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isIn<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.IN, value: values),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isNotIn<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.NOT_IN, value: values),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isBetween<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.BETWEEN, value: values),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isNotBetween<Value>(String field, List<Value> values) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.NOT_BETWEEN, value: values),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isLike<Value>(String field, String pattern) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.LIKE, value: pattern),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isNotLike<Value>(String field, String pattern) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
          field, (operator: Operator.NOT_LIKE, value: pattern));
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isNull(String field) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.NULL, value: null),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> isNotNull(String field) {
    final newChild = _WhereClauseImpl(query)
      ..clauseValue = WhereClauseValue(
        field,
        (operator: Operator.NOT_NULL, value: null),
      );
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  Future<void> delete() {
    return DeleteQuery(query.tableName, whereClause: this)
        .driver(query.runner)
        .execute();
  }

  @override
  Future<List<Result>> findMany() => query.all();

  @override
  Future<Result?> findOne() => query.get();

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
  WhereClause<Result> where<Value>(
    String field,
    String condition, [
    Value? value,
  ]) {
    final newChild = _WhereClauseImpl<Result>(query)
      ..clauseValue = WhereClauseValue.from(field, condition, value);
    children.add((LogicalOperator.AND, newChild));
    return this;
  }

  @override
  WhereClause<Result> orWhere<Value>(
    String field,
    String condition, [
    Value? value,
  ]) {
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
  Future<num> average(String field) => AverageAggregate(query, field).get();

  @override
  Future<int> count({String? field, bool distinct = false}) {
    return CountAggregate(query, field).get();
  }

  @override
  Future<num> max(String field) => MaxAggregate(query, field).get();

  @override
  Future<num> min(String field) => MinAggregate(query, field).get();

  @override
  Future<num> sum(String field) => SumAggregate(query, field).get();

  @override
  Future<String> groupConcat(String field, String separator) {
    return GroupConcatAggregate(query, field, separator).get();
  }

  @override
  String get statement => query.statement;
}
