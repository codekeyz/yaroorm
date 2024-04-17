// ignore_for_file: constant_identifier_names

part of '../query/query.dart';

typedef WhereBuilder<T extends Entity<T>> = WhereClause Function(WhereClauseBuilder<T> builder);

mixin WhereOperation {
  $AndGroup and(List<WhereClause> values) => $AndGroup._(values);

  $OrGroup or(List<WhereClause> values) => $OrGroup._(values);

  WhereClauseValue $equal<T>(String field, T value);

  WhereClauseValue $notEqual<T>(String field, T value);

  WhereClauseValue $isNull(String field);

  WhereClauseValue $isNotNull(String field);

  WhereClauseValue<List<T>> $isIn<T>(String field, List<T> values);

  WhereClauseValue<List<T>> $isNotIn<T>(String field, List<T> values);

  WhereClauseValue $isLike(String field, String pattern);

  WhereClauseValue $isNotLike(String field, String pattern);

  WhereClauseValue<List<T>> $isBetween<T>(String field, List<T> values);

  WhereClauseValue<List<T>> $isNotBetween<T>(String field, List<T> values);
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

abstract interface class WhereClause {
  final List<WhereClause> values;
  WhereClause(this.values);
}

class $AndGroup extends WhereClause {
  $AndGroup._(super.values);
}

class $OrGroup extends WhereClause {
  $OrGroup._(super.values);
}

class WhereClauseValue<ValueType> extends WhereClause {
  final String field;
  final Operator operator;
  final ValueType value;

  WhereClauseValue._(this.field, this.operator, this.value) : super(const []) {
    if ([Operator.BETWEEN, Operator.NOT_BETWEEN].contains(operator)) {
      if (value is! Iterable || (value as Iterable).length != 2) {
        throw ArgumentError(
          '${operator.name} requires a List with length 2 (val1, val2)',
          '$field ${operator.name} $value',
        );
      }
    }
  }
}

final class WhereClauseBuilder<T extends Entity<T>> with WhereOperation {
  WhereClauseBuilder._();

  @override
  WhereClauseValue<V> $equal<V>(String field, V value) {
    return WhereClauseValue<V>._(field, Operator.EQUAL, value);
  }

  @override
  WhereClauseValue $notEqual<V>(String field, V value) {
    return WhereClauseValue._(field, Operator.NOT_EQUAL, value);
  }

  @override
  WhereClauseValue<List<V>> $isIn<V>(String field, List<V> values) {
    return WhereClauseValue._(field, Operator.IN, values);
  }

  @override
  WhereClauseValue<List<V>> $isNotIn<V>(String field, List<V> values) {
    return WhereClauseValue._(field, Operator.NOT_IN, values);
  }

  @override
  WhereClauseValue $isLike(String field, String pattern) {
    return WhereClauseValue._(field, Operator.LIKE, pattern);
  }

  @override
  WhereClauseValue $isNotLike(String field, String pattern) {
    return WhereClauseValue._(field, Operator.NOT_LIKE, pattern);
  }

  @override
  WhereClauseValue $isNull(String field) {
    return WhereClauseValue._(field, Operator.NULL, null);
  }

  @override
  WhereClauseValue $isNotNull(String field) {
    return WhereClauseValue._(field, Operator.NOT_NULL, null);
  }

  @override
  WhereClauseValue<List<V>> $isBetween<V>(String field, List<V> values) {
    return WhereClauseValue._(field, Operator.BETWEEN, values);
  }

  @override
  WhereClauseValue<List<V>> $isNotBetween<V>(String field, List<V> values) {
    return WhereClauseValue._(field, Operator.NOT_BETWEEN, values);
  }
}
