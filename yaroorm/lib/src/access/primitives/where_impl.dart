part of '../access.dart';

class WhereClauseImpl extends WhereClause {
  WhereClauseImpl(super.value, super._query);

  @override
  WhereClause where<Value>(String field, String condition, [Value? val]) {
    final clauseValue = WhereClauseValue.from(field, condition, val);
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> val) {
    final clauseValue =
        WhereClauseValue(field, (operator: Operator.IN, value: val));

    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereNotIn<Value>(String field, List<Value> val) {
    final clauseValue =
        WhereClauseValue(field, (operator: Operator.NOT_IN, value: val));

    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereLike<Value>(String field, String pattern) {
    final clauseValue =
        WhereClauseValue(field, (operator: Operator.LIKE, value: pattern));
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereNotLike<Value>(String field, String pattern) {
    final clauseValue =
        WhereClauseValue(field, (operator: Operator.NOT_LIKE, value: pattern));
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereBetween<Value>(String field, WhereBetweenArgs<Value> args) {
    final clauseValue = WhereClauseValue(
      field,
      (operator: Operator.BETWEEN, value: [args.$1, args.$2]),
    );

    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereNotBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  ) {
    final clauseValue = WhereClauseValue(
        field, (operator: Operator.NOT_BETWEEN, value: [args.$1, args.$2]));
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereNull(String field) {
    final clauseValue =
        WhereClauseValue(field, (operator: Operator.NULL, value: null));
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause whereNotNull(String field) {
    final clauseValue =
        WhereClauseValue(field, (operator: Operator.NOT_NULL, value: null));
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.AND,
        WhereClauseImpl(clauseValue, _query),
      ));
  }

  @override
  WhereClause orWhere<Value>(String field, String condition, [Value? val]) {
    final clauseValue = WhereClauseValue.from(field, condition, val);
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add((
        LogicalOperator.OR,
        WhereClauseImpl(clauseValue, _query),
      ));
  }
}

class CompositeWhereClause extends WhereClauseImpl {
  final List<CombineClause<WhereClause>> subparts = [];

  CompositeWhereClause(WhereClauseImpl parent)
      : super(parent.value, parent._query);

  @override
  CompositeWhereClause where<Value>(String field, String condition,
      [Value? val]) {
    final clauseValue = WhereClauseValue.from(field, condition, val);
    subparts.add((LogicalOperator.AND, WhereClauseImpl(clauseValue, _query)));
    return this;
  }

  @override
  WhereClause whereIn<Value>(String field, List<Value> val) {
    final clauseValue = WhereClauseValue(
      field,
      (operator: Operator.IN, value: val),
    );
    subparts.add((LogicalOperator.AND, WhereClauseImpl(clauseValue, _query)));
    return this;
  }

  @override
  WhereClause whereBetween<Value>(String field, WhereBetweenArgs<Value> args) {
    final clauseValue = WhereClauseValue(
      field,
      (operator: Operator.BETWEEN, value: [args.$1, args.$2]),
    );
    subparts.add((LogicalOperator.AND, WhereClauseImpl(clauseValue, _query)));
    return this;
  }

  @override
  CompositeWhereClause orWhere<Value>(String field, String condition,
      [Value? val]) {
    final clauseValue = WhereClauseValue.from(field, condition, val);
    subparts.add((LogicalOperator.OR, WhereClauseImpl(clauseValue, _query)));
    return this;
  }
}
