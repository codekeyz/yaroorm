// ignore_for_file: constant_identifier_names

part of '../query.dart';

mixin WhereOperation<Result> {
  WhereClause where<Value>(
    String field,
    String condition, [
    Value? value,
  ]);

  WhereClause<Result> whereEqual<Value>(String field, Value value);

  WhereClause<Result> whereNotEqual<Value>(String field, Value value);

  WhereClause<Result> whereNull(String field);

  WhereClause<Result> whereNotNull(String field);

  WhereClause<Result> whereIn<Value>(String field, List<Value> values);

  WhereClause<Result> whereNotIn<Value>(String field, List<Value> values);

  WhereClause<Result> whereLike<Value>(String field, String pattern);

  WhereClause<Result> whereNotLike<Value>(String field, String pattern);

  WhereClause<Result> whereBetween<Value>(String field, List<Value> args);

  WhereClause<Result> whereNotBetween<Value>(String field, List<Value> args);
}

abstract class Clause {
  WhereClauseValue? clauseValue;
}

enum LogicalOperator { AND, OR }

typedef CombineClause<T> = (LogicalOperator operator, T clause);

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
      _ => throw ArgumentError.value(condition, null, 'Condition $condition is not known')
    };

class WhereClauseValue<A> {
  final String field;
  final CompareWithValue comparer;

  WhereClauseValue(this.field, this.comparer) {
    final operator = comparer.operator;
    final value = comparer.value;
    if ([Operator.BETWEEN, Operator.NOT_BETWEEN].contains(operator)) {
      if (value is! List || value.length != 2) {
        throw ArgumentError(
          '${operator.name} requires a List with length 2 (val1, val2)',
          '$field ${operator.name} $value',
        );
      }
    }
  }

  factory WhereClauseValue.from(String field, String condition, value) {
    final operator = _strToOperator(condition);

    return WhereClauseValue(field, (operator: operator, value: value));
  }
}

abstract class WhereClause<Result> extends Clause
    with WhereOperation<Result>, FindOperation<Result>, LimitOperation<Result>, OrderByOperation<WhereClause<Result>> {
  final Query<Result> _query;

  final LogicalOperator operator;
  final List<CombineClause<WhereClauseValue>> subparts = [];

  WhereClause(this._query, {this.operator = LogicalOperator.AND});

  WhereClause<Result> orWhere<Value>(String field, String condition, [Value? value]);

  Query<Result> whereFunc(Function(WhereClause<Result> query) builder);

  Query<Result> orWhereFunc(Function(WhereClause<Result> query) builder);

  Future<void> update(Map<String, dynamic> values);

  Future<void> delete();

  String get statement;
}
