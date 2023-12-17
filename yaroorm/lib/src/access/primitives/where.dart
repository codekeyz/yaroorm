part of '../access.dart';

typedef WhereBetweenArgs<Value> = (Value var1, Value var2);

mixin WhereOperation {
  WhereClause where<Value>(
    String field,
    String condition, [
    Value? val,
  ]);

  WhereClause orWhere<Value>(
    String field,
    String condition, [
    Value? val,
  ]);

  WhereClause whereIn<Value>(String field, List<Value> val);

  WhereClause whereBetween<Value>(String field, WhereBetweenArgs<Value> args);
}

abstract class Clause<T> {
  final T value;

  const Clause(this.value);
}

enum LogicalOperator { AND, OR }

typedef CombineClause<T extends Clause> = (LogicalOperator operator, T clause);

enum Operator {
  IN,
  NOT_IN,
  NULL,
  LIKE,
  NOT_LIKE,
  BETWEEN,
  NOT_BETWEEN,
  EQUAL,
  NOT_EQUAL,
  NOT_NULL,
  LESS_THAN,
  GREAT_THAN,
  GREATER_THAN_OR_EQUAL_TO,
  LESS_THEN_OR_EQUAL_TO,
}

typedef CompareWithValue<Value> = ({Operator operator, Value? value});

Operator _strToOperator(String condition) => switch (condition) {
      '=' => Operator.EQUAL,
      '!=' => Operator.NOT_EQUAL,
      '<' => Operator.LESS_THAN,
      '>' => Operator.GREAT_THAN,
      '>=' => Operator.GREATER_THAN_OR_EQUAL_TO,
      '<=' => Operator.LESS_THEN_OR_EQUAL_TO,
      //
      'in' => Operator.IN,
      'not in' => Operator.NOT_IN,
      //
      'like' => Operator.LIKE,
      'not like' => Operator.NOT_LIKE,
      //
      'null' => Operator.NULL,
      'not null' => Operator.NOT_NULL,
      //
      'between' => Operator.BETWEEN,
      'not between' => Operator.NOT_BETWEEN,
      _ => throw ArgumentError.value(condition, null,
          'Either condition is not known or Use one of the defined functions')
    };

class WhereClauseValue<A> {
  final String field;
  final CompareWithValue comparer;

  const WhereClauseValue(this.field, this.comparer);

  factory WhereClauseValue.from(
    String field,
    String condition,
    dynamic value,
  ) =>
      WhereClauseValue(
          field, (operator: _strToOperator(condition), value: value));
}

abstract class WhereClause extends Clause<WhereClauseValue>
    with
        WhereOperation,
        FindOperation,
        LimitOperation,
        OrderByOperation<WhereClause> {
  final Query _query;

  WhereClause(super.value, this._query);

  @override
  WhereClause where<Value>(String field, String condition, [Value? val]);

  @override
  WhereClause orWhere<Value>(String field, String condition, [Value? val]);

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
  Future<T?> findOne<T>() => _query.first<T>();

  @override
  Future<List<T>> findMany<T>() => _query.all<T>();

  @override
  Future<List<T>> take<T>(int limit) => _query.take<T>(limit);

  Future<void> delete() => _query._delete(this);

  Future<void> update(Map<String, dynamic> values) =>
      _query._update(this, values);

  String get statement => _query.statement;
}
