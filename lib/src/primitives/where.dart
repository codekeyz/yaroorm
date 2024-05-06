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
  WhereClause(this.values, {String? table});

  @internal
  void validate(List<Join> joins);
}

class $AndGroup extends WhereClause {
  $AndGroup._(super.values);

  @override
  void validate(List<Join> joins) {
    final clauseValues = values.whereType<WhereClauseValue>();
    for (final val in clauseValues) {
      val.validate(joins);
    }
  }
}

class $OrGroup extends WhereClause {
  $OrGroup._(super.values);

  @override
  void validate(List<Join> joins) {
    final clauseValues = values.whereType<WhereClauseValue>();
    for (final val in clauseValues) {
      val.validate(joins);
    }
  }
}

class WhereClauseValue<ValueType> extends WhereClause {
  final String field;
  final Operator operator;
  final ValueType value;

  final String? table;

  WhereClauseValue._(
    this.field,
    this.operator,
    this.value, {
    this.table,
  }) : super(const []) {
    if ([Operator.BETWEEN, Operator.NOT_BETWEEN].contains(operator)) {
      if (value is! Iterable || (value as Iterable).length != 2) {
        throw ArgumentError(
          '${operator.name} requires a List with length 2 (val1, val2)',
          '$field ${operator.name} $value',
        );
      }
    }
  }

  @override
  void validate(List<Join> joins) {
    if (table == null) return;
    final tableJoined = joins.any((e) => [e.onTable, e.fromTable].contains(table));
    if (!tableJoined) {
      throw ArgumentError(
        'No Joins found to enable `$table.$field ${operator.name} $value` Did you forget to call `.withRelations` ?',
      );
    }
  }
}

class WhereClauseBuilder<T extends Entity<T>> with WhereOperation {
  final String? table;

  const WhereClauseBuilder({this.table});

  @override
  WhereClauseValue<V> $equal<V>(String field, V value) {
    _ensureHasField(field);
    return WhereClauseValue<V>._(field, Operator.EQUAL, value, table: table);
  }

  @override
  WhereClauseValue $notEqual<V>(String field, V value) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.NOT_EQUAL, value, table: table);
  }

  @override
  WhereClauseValue<List<V>> $isIn<V>(String field, List<V> values) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.IN, values, table: table);
  }

  @override
  WhereClauseValue<List<V>> $isNotIn<V>(String field, List<V> values) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.NOT_IN, values, table: table);
  }

  @override
  WhereClauseValue $isLike(String field, String pattern) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.LIKE, pattern, table: table);
  }

  @override
  WhereClauseValue $isNotLike(String field, String pattern) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.NOT_LIKE, pattern, table: table);
  }

  @override
  WhereClauseValue $isNull(String field) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.NULL, null, table: table);
  }

  @override
  WhereClauseValue $isNotNull(String field) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.NOT_NULL, null, table: table);
  }

  @override
  WhereClauseValue<List<V>> $isBetween<V>(String field, List<V> values) {
    _ensureHasField(field);
    return WhereClauseValue._(field, Operator.BETWEEN, values, table: table);
  }

  @override
  WhereClauseValue<List<V>> $isNotBetween<V>(String field, List<V> values) {
    _ensureHasField(field);
    return WhereClauseValue._(
      field,
      Operator.NOT_BETWEEN,
      values,
      table: table,
    );
  }

  void _ensureHasField(String field) {
    final typeData = Query.getEntity<T>();
    final hasField = typeData.columns.any((e) => e.columnName == field);
    if (!hasField) {
      throw ArgumentError(
        'Field `${typeData.tableName}.$field` not found on $T Entity. Did you mis-spell it ?',
      );
    }
  }
}
