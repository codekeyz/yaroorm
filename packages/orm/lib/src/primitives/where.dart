// ignore_for_file: constant_identifier_names

import '../database/entity/entity.dart' hide value;
import '../query/aggregates.dart';
import '../query/query.dart';

part '_where_impl.dart';

typedef WhereBuilder<T extends Entity> = WhereClause<T> Function(
  Query<T> query,
);

mixin WhereOperation<Result extends Entity> {
  WhereClause<Result> where<Value>(
    String field,
    String condition, [
    Value? value,
  ]);

  WhereClause<Result> orWhere<Value>(
    String field,
    String condition, [
    Value? value,
  ]);

  WhereClause<Result> equal<Value>(String field, Value value);

  WhereClause<Result> notEqual<Value>(String field, Value value);

  WhereClause<Result> isNull(String field);

  WhereClause<Result> isNotNull(String field);

  WhereClause<Result> isIn<Value>(String field, List<Value> values);

  WhereClause<Result> isNotIn<Value>(String field, List<Value> values);

  WhereClause<Result> isLike<Value>(String field, String pattern);

  WhereClause<Result> isNotLike<Value>(String field, String pattern);

  WhereClause<Result> isBetween<Value>(String field, List<Value> values);

  WhereClause<Result> isNotBetween<Value>(String field, List<Value> values);

  Query<Result> orWhereFunc(Function(Query<Result> query) builder);

  Query<Result> whereFunc(Function(Query<Result> query) builder);
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

class WhereClauseValue<ValueType> {
  final String field;
  final CompareWithValue<ValueType> comparer;

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

abstract class WhereClause<T extends Entity>
    with WhereOperation<T>, FindOperation<T>, LimitOperation<T>, OrderByOperation<WhereClause<T>>, AggregateOperation {
  final List<CombineClause<WhereClause<T>>> children = [];

  List<CombineClause<WhereClause<T>>> get group => children.isEmpty
      ? const []
      : [
          if (clauseValue != null)
            (operator, WhereClause.create<T>(query, operator: operator)..clauseValue = clauseValue),
          ...children
        ];

  Set<LogicalOperator> get operators => {
        operator,
        if (children.isNotEmpty) ...children.map((e) => e.$1),
      };

  final Query<T> query;

  final LogicalOperator operator;

  WhereClauseValue? clauseValue;

  WhereClause(this.query, {this.operator = LogicalOperator.AND});

  static WhereClause<Result> create<Result extends Entity>(
    Query<Result> query, {
    LogicalOperator operator = LogicalOperator.AND,
    WhereClauseValue? value,
  }) {
    return _WhereClauseImpl<Result>(query, operator: operator)..clauseValue = value;
  }

  Future<void> delete();

  String get statement;
}
