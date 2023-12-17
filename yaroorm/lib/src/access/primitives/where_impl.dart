part of '../access.dart';

class WhereClauseImpl extends WhereClause {
  WhereClauseImpl(super._query, super.value);

  @override
  WhereClause orWhere<Value>(String field, String condition, [Value? value]) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.OR,
        WhereClause.fromString(field, condition, value, query: _query),
      ));
  }

  @override
  WhereClause where<Value>(String field, String condition, [Value? value]) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromString(field, condition, value, query: _query),
      ));
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> values) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.IN, values, query: _query),
      ));
  }

  @override
  WhereClause whereNotIn<Value>(String field, List<Value> values) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.NOT_IN, values, query: _query),
      ));
  }

  @override
  WhereClause whereLike<Value>(String field, String pattern) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.LIKE, pattern, query: _query),
      ));
  }

  @override
  WhereClause whereNotLike<Value>(String field, String pattern) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.NOT_LIKE, pattern,
            query: _query),
      ));
  }

  @override
  WhereClause whereBetween<Value>(String field, WhereBetweenArgs<Value> args) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.BETWEEN, args, query: _query),
      ));
  }

  @override
  WhereClause whereNotBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  ) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.NOT_BETWEEN, args,
            query: _query),
      ));
  }

  @override
  WhereClause whereNull(String field) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.NULL, null, query: _query),
      ));
  }

  @override
  WhereClause whereNotNull(String field) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClause.fromOperator(field, Operator.NOT_NULL, null, query: _query),
      ));
  }
}

class CompositeWhereClause extends WhereClause {
  final List<CombineClause<WhereClause>> subparts = [];

  CompositeWhereClause(WhereClauseImpl parent)
      : super(parent._query, parent.clauseVal);

  @override
  CompositeWhereClause where<Value>(String field, String condition,
      [Value? value]) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromString(field, condition, value, query: _query)
    ));
    return this;
  }

  @override
  CompositeWhereClause orWhere<Value>(String field, String condition,
      [Value? value]) {
    subparts.add((
      LogicalOperator.OR,
      WhereClause.fromString(field, condition, value, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> values) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.IN, values, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereNotIn<Value>(String field, List<Value> values) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.NOT_IN, values, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereBetween<Value>(String field, WhereBetweenArgs<Value> args) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.BETWEEN, args, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereNotBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  ) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.NOT_BETWEEN, args, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereLike<Value>(String field, String pattern) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.LIKE, pattern, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereNotLike<Value>(String field, String pattern) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.NOT_LIKE, pattern, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereNull(String field) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.NULL, null, query: _query)
    ));
    return this;
  }

  @override
  WhereClause whereNotNull(String field) {
    subparts.add((
      LogicalOperator.AND,
      WhereClause.fromOperator(field, Operator.NOT_NULL, null, query: _query)
    ));
    return this;
  }
}
