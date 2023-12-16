part of '../query.dart';

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

class WhereClause<Model extends Entity> extends Clause<WhereClauseValue>
    with
        FindOneOperation<Model>,
        LimitOperation<Future<List<Model>>>,
        OrderByOperation<WhereClause<Model>> {
  final EntityTableInterface<Model> _query;

  WhereClause(super.value, this._query);

  CompositeWhereClause<Model> and<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query._whereClause = CompositeWhereClause<Model>(this)
      ..subparts.add(LogicalClause(
          LogicalOperator.AND,
          WhereClause<Model>(
              (field: field, condition: condition, value: val), _query)));
  }

  CompositeWhereClause<Model> or<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query._whereClause = CompositeWhereClause<Model>(this)
      ..subparts.add(
        LogicalClause(
            LogicalOperator.OR,
            WhereClause<Model>(
                (field: field, condition: condition, value: val), _query)),
      );
  }

  @override
  Future<Model?> findOne() => _query.findOne();

  @override
  Future<List<Model>> limit(int limit) => _query.limit(limit);

  @override
  WhereClause<Model> orderBy(String field, OrderByDirection direction) {
    _query.orderByProps.add((field: field, direction: direction));
    return this;
  }

  Future<List<Model>> get() => _query.all();
}

class CompositeWhereClause<QueryResult extends Entity>
    extends WhereClause<QueryResult> {
  final List<LogicalClause<WhereClause<QueryResult>>> subparts = [];

  CompositeWhereClause(WhereClause<QueryResult> parent)
      : super(parent.value, parent._query);

  @override
  CompositeWhereClause<QueryResult> and<Type>(
    String field,
    String condition,
    Type val,
  ) {
    subparts.add(LogicalClause(
      LogicalOperator.AND,
      WhereClause<QueryResult>(
          (field: field, condition: condition, value: val), _query),
    ));
    return this;
  }

  @override
  CompositeWhereClause<QueryResult> or<Type>(
    String field,
    String condition,
    Type val,
  ) {
    subparts.add(LogicalClause(
      LogicalOperator.OR,
      WhereClause<QueryResult>(
          (field: field, condition: condition, value: val), _query),
    ));
    return this;
  }
}
