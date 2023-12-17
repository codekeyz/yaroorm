part of '../access.dart';

abstract class Clause<T> {
  final T value;

  const Clause(this.value);
}

// ignore: constant_identifier_names
enum LogicalOperator { AND, OR }

class LogicalClause<T extends Clause> {
  final LogicalOperator operator;
  final T clause;

  const LogicalClause(this.operator, this.clause);
}

typedef WhereClauseValue<A> = ({String field, String condition, A? value});

class WhereClause extends Clause<WhereClauseValue>
    with FindOperation, LimitOperation, OrderByOperation<WhereClause> {
  final Query _query;

  WhereClause(super.value, this._query);

  CompositeWhereClause andWhere<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add(LogicalClause(
        LogicalOperator.AND,
        WhereClause((field: field, condition: condition, value: val), _query),
      ));
  }

  CompositeWhereClause orWhere<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query._whereClause = CompositeWhereClause(this)
      ..subparts.add(LogicalClause(
        LogicalOperator.OR,
        WhereClause((field: field, condition: condition, value: val), _query),
      ));
  }

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

  Future<void> delete() => _query._delete(this);

  Future<void> update(Map<String, dynamic> values) =>
      _query._update(this, values);

  String get statement => _query.statement;

  @override
  Future<T?> findOne<T>() => _query.first<T>();

  @override
  Future<List<T>> findMany<T>() => _query.all<T>();

  @override
  Future<List<T>> take<T>(int limit) => _query.take<T>(limit);
}

class CompositeWhereClause extends WhereClause {
  final List<LogicalClause<WhereClause>> subparts = [];

  CompositeWhereClause(WhereClause parent) : super(parent.value, parent._query);

  @override
  CompositeWhereClause andWhere<Type>(
    String field,
    String condition,
    Type val,
  ) {
    subparts.add(LogicalClause(
      LogicalOperator.AND,
      WhereClause((field: field, condition: condition, value: val), _query),
    ));
    return this;
  }

  @override
  CompositeWhereClause orWhere<Type>(
    String field,
    String condition,
    Type val,
  ) {
    subparts.add(LogicalClause(
      LogicalOperator.OR,
      WhereClause((field: field, condition: condition, value: val), _query),
    ));
    return this;
  }
}
