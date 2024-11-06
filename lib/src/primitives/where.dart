// ignore_for_file: constant_identifier_names

part of '../query/query.dart';

typedef WhereBuilder<T extends Entity<T>> = WhereClause Function(WhereClauseBuilder<T> builder);

$AndGroup and(List<WhereClauseValue> values) => $AndGroup._(values);

$OrGroup or(List<WhereClauseValue> values) => $OrGroup._(values);

mixin WhereOperation {
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
  const WhereClause(this.values, {String? table});

  @internal
  void validate(List<Join> joins);

  void _withConverters(Map<Type, EntityTypeConverter> converters);
}

class $AndGroup extends WhereClause {
  const $AndGroup._(super.values);

  @override
  void validate(List<Join> joins) {
    final clauseValues = values.whereType<WhereClauseValue>();
    for (final val in clauseValues) {
      val.validate(joins);
    }
  }

  @override
  void _withConverters(Map<Type, EntityTypeConverter> converters) {
    final clauseValues = values.whereType<WhereClauseValue>();
    for (final val in clauseValues) {
      val._withConverters(converters);
    }
  }
}

class $OrGroup extends WhereClause {
  const $OrGroup._(super.values);

  @override
  void validate(List<Join> joins) {
    final clauseValues = values.whereType<WhereClauseValue>();
    for (final val in clauseValues) {
      val.validate(joins);
    }
  }

  @override
  void _withConverters(Map<Type, EntityTypeConverter> converters) {
    final clauseValues = values.whereType<WhereClauseValue>();
    for (final val in clauseValues) {
      val._withConverters(converters);
    }
  }
}

class WhereClauseValue<ValueType> extends WhereClause {
  final String field;
  final Operator operator;
  final ValueType value;

  final String table;

  final Map<Type, EntityTypeConverter> _converters = {};

  WhereClauseValue._(
    this.field,
    this.operator,
    this.value, {
    required this.table,
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

  dynamic get dbValue {
    final typeConverter = _converters[ValueType];
    if (typeConverter == null) return value;
    return typeConverter.toDbType(value);
  }

  @override
  void validate(List<Join> joins) {
    if (joins.isNotEmpty) {
      final tableJoined = joins.any((e) => [e.on.table, e.origin.table].contains(table));
      if (!tableJoined) {
        throw ArgumentError(
          'No Joins found to enable `$table.$field ${operator.name} $value` Did you forget to call `.withRelations` ?',
        );
      }
    }
  }

  WhereClause operator &(WhereClauseValue other) => and([this, other]);

  WhereClause operator |(WhereClauseValue other) => or([this, other]);

  @override
  void _withConverters(Map<Type, EntityTypeConverter> converters) {
    _converters
      ..clear()
      ..addAll(converters);
  }
}

class WhereClauseBuilder<T extends Entity<T>> with WhereOperation {
  final String table;

  WhereClauseBuilder() : table = Query.getEntity<T>().tableName;

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
    return WhereClauseValue._(field, Operator.NOT_BETWEEN, values, table: table);
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
