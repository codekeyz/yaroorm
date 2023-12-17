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

class WhereClause<Model extends Entity> extends Clause<WhereClauseValue>
    with
        FindOperation<Model>,
        LimitOperation<Future<List<Model>>>,
        OrderByOperation<WhereClause<Model>> {
  final Query<Model> _query;

  WhereClause(super.value, this._query);

  CompositeWhereClause<Model> and<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query._whereClause = CompositeWhereClause<Model>(this)
      ..subparts.add(
        LogicalClause(
          LogicalOperator.AND,
          WhereClause<Model>(
            (field: field, condition: condition, value: val),
            _query,
          ),
        ),
      );
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
            (field: field, condition: condition, value: val),
            _query,
          ),
        ),
      );
  }

  @override
  WhereClause<Model> orderBy(String field, OrderByDirection direction) {
    _query.orderByProps.add((field: field, direction: direction));
    return this;
  }

  @override
  Future<Model?> findOne() => _query.findOne();

  @override
  Future<List<Model>> findMany() => _query.findMany();

  @override
  Future<List<Model>> limit(int limit) => _query.limit(limit);

  Future<void> delete() => _query._delete(this);

  Future<void> update(Map<String, dynamic> values) =>
      _query._update(this, values);

  String get statement => _query.statement;
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
        (field: field, condition: condition, value: val),
        _query,
      ),
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
        (field: field, condition: condition, value: val),
        _query,
      ),
    ));
    return this;
  }
}
