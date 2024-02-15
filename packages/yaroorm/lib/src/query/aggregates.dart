import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';

import 'query.dart';

abstract interface class AggregateFunction<T> {
  final List<String> selections;
  final List<WhereClause> whereClauses;
  final String tableName;
  final DriverContract driver;

  String get name;

  const AggregateFunction(
    this.driver,
    this.tableName, {
    this.selections = const [],
    this.whereClauses = const [],
  });

  AggregateFunction._init(Query query, this.selections)
      : driver = query.queryDriver,
        tableName = query.tableName,
        whereClauses = query.whereClauses,
        assert(
          query.fieldSelections.isEmpty,
          'You can not use selections with aggregate functions',
        );

  Future<T> get() async {
    final statement = driver.serializer.acceptAggregate(this);
    final result = await driver.rawQuery(statement);
    final value = result[0].values.first;
    if (value is T) return value;
    return switch (T) {
      const (int) ||
      const (double) ||
      const (num) =>
        value == null ? 0 : num.parse(value.toString()),
      const (String) => value.toString(),
      _ => throw Exception('Null value returned for aggregate: $statement'),
    } as T;
  }

  String get statement => driver.serializer.acceptAggregate(this);
}

class SumAggregate extends AggregateFunction<num> {
  SumAggregate(Query query, String field) : super._init(query, [field]);

  @override
  String get name => 'SUM';
}

class CountAggregate extends AggregateFunction<int> {
  CountAggregate(Query query, String field) : super._init(query, [field]);

  @override
  String get name => 'COUNT';
}

class AverageAggregate extends AggregateFunction<num> {
  AverageAggregate(Query query, String field) : super._init(query, [field]);

  @override
  String get name => 'AVG';
}

class MaxAggregate extends AggregateFunction<num> {
  MaxAggregate(Query query, String field) : super._init(query, [field]);

  @override
  String get name => 'MAX';
}

class MinAggregate extends AggregateFunction<num> {
  MinAggregate(Query query, String field) : super._init(query, [field]);

  @override
  String get name => 'MIN';
}

class GroupConcatAggregate extends AggregateFunction<String> {
  final String? separator;

  GroupConcatAggregate(Query query, String field, {this.separator})
      : super._init(query, [field]);

  @override
  String get name => 'GROUP_CONCAT';
}
