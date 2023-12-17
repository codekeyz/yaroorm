// ignore_for_file: constant_identifier_names

part of '../access.dart';

typedef WhereBetweenArgs<Value> = (Value var1, Value var2);

mixin WhereOperation {
  WhereClause where<Value>(
    String field,
    String condition, [
    Value? value,
  ]);

  WhereClause whereNull(String field);

  WhereClause whereNotNull(String field);

  WhereClause whereIn<Value>(String field, List<Value> values);

  WhereClause whereNotIn<Value>(String field, List<Value> values);

  WhereClause whereLike<Value>(String field, String pattern);

  WhereClause whereNotLike<Value>(String field, String pattern);

  WhereClause whereBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  );

  WhereClause whereNotBetween<Value>(
    String field,
    WhereBetweenArgs<Value> args,
  );
}

abstract class Clause<T> {
  final T clauseVal;

  const Clause(this.clauseVal);
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

  factory WhereClauseValue.from(String field, String condition, value) {
    final operator = _strToOperator(condition);
    if ([Operator.BETWEEN, Operator.NOT_BETWEEN].contains(operator)) {
      if (value is! List || value.length != 2) {
        throw ArgumentError.value(
            value, null, '$operator requires [val1, val2] as value');
      }
      final WhereBetweenArgs whereArgs = (value[0], value[1]);
      value = whereArgs;
    }
    return WhereClauseValue(field, (operator: operator, value: value));
  }
}

abstract class WhereClause extends Clause<WhereClauseValue>
    with
        WhereOperation,
        FindOperation,
        LimitOperation,
        OrderByOperation<WhereClause> {
  final Query _query;

  WhereClause(this._query, super.clauseVal);

  static WhereClause fromString(String field, String condition, dynamic value,
      {required Query query}) {
    return WhereClauseImpl(
      query,
      WhereClauseValue.from(field, condition, value),
    );
  }

  static WhereClause fromOperator(
    String field,
    Operator operator,
    dynamic value, {
    required Query query,
  }) {
    return WhereClauseImpl(
      query,
      WhereClauseValue(field, (operator: operator, value: value)),
    );
  }

  WhereClause orWhere<Value>(String field, String condition, [Value? value]);

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
