import 'query.dart';

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

class WhereClause<QueryResult extends Entity> extends Clause<WhereClauseValue> {
  final EntityTableInterface<QueryResult> _query;

  WhereClause(super.value, this._query);

  EntityTableInterface<QueryResult> get query => _query;

  CompositeWhereClause<QueryResult> and<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query.whereClause = CompositeWhereClause<QueryResult>(this)
      ..subparts.add(LogicalClause(
        LogicalOperator.AND,
        WhereClause<QueryResult>(
            (field: field, condition: condition, value: val), _query),
      ));
  }

  CompositeWhereClause<QueryResult> or<ValueType>(
    String field,
    String condition,
    ValueType val,
  ) {
    return _query.whereClause = CompositeWhereClause<QueryResult>(this)
      ..subparts.add(LogicalClause(
        LogicalOperator.OR,
        WhereClause<QueryResult>(
            (field: field, condition: condition, value: val), _query),
      ));
  }
}

class CompositeWhereClause<QueryResult extends Entity>
    extends WhereClause<QueryResult> {
  final List<LogicalClause<WhereClause<QueryResult>>> subparts = [];

  CompositeWhereClause(WhereClause<QueryResult> parent)
      : super(parent.value, parent._query);

  @override
  CompositeWhereClause<QueryResult> and<Type>(
      String field, String condition, Type val) {
    subparts.add(LogicalClause(
      LogicalOperator.AND,
      WhereClause<QueryResult>(
          (field: field, condition: condition, value: val), _query),
    ));
    return this;
  }

  @override
  CompositeWhereClause<QueryResult> or<Type>(
      String field, String condition, Type val) {
    subparts.add(LogicalClause(
      LogicalOperator.OR,
      WhereClause<QueryResult>(
          (field: field, condition: condition, value: val), _query),
    ));
    return this;
  }
}

typedef OrderBy = ({String field, OrderByDirection order});

abstract interface class EntityOperations<Model extends Entity> {
  WhereClause<Model> where<Value>(String field, String optor, Value value);

  Future<Model> insert(Model entity);

  Future<Model?> findOne();

  Future<List<Model>> all();
}

abstract class QueryPrimitiveSerializer {
  String acceptWhereClause(WhereClause clause);

  String acceptQuery(EntityTableInterface query);

  String acceptSelect(List<String> fields);

  String acceptOrderBy(List<OrderBy> orderBys);
}
