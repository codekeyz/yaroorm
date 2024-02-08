import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';

abstract interface class AggregateFunction<T> {
  final String selections;
  final WhereClause? where;
  final String tableName;
  final DriverContract driver;

  String get name;

  AggregateFunction(
    this.driver,
    this.tableName,
    this.selections, {
    this.where,
  });

  Future<T> get() async {
    final statement = driver.serializer.acceptAggregate(this);
    return await driver.execute(statement) as T;
  }

  String get statement => driver.serializer.acceptAggregate(this);
}

class SumAggregate<T> extends AggregateFunction<T> {
  SumAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'SUM';
}

class CountAggregate<T> extends AggregateFunction<T> {
  CountAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'COUNT';
}

class AverageAggregate<T> extends AggregateFunction<T> {
  AverageAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'AVG';
}

class MaxAggregate<T> extends AggregateFunction<T> {
  MaxAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'MAX';
}

class MinAggregate<T> extends AggregateFunction<T> {
  MinAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'MIN';
}

class TotalAggregate<T> extends AggregateFunction<T> {
  TotalAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'TOTAL';
}

class ConcatAggregate<T> extends AggregateFunction<T> {
  ConcatAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'GROUP_CONCAT';
}
