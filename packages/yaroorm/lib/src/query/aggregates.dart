import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';

abstract interface class AggregateFunction<T> {
  final Set<String> selections;
  final WhereClause? where;
  final DriverContract driver;
  final String tableName;

  String get name;

  const AggregateFunction(
    this.driver,
    this.tableName, {
    this.selections = const {'*'},
    this.where,
  });

  Future<T> get() async {
    final statement = driver.serializer.acceptAggregate(this);
    return await driver.execute(statement) as T;
  }
}

class SumAggregate extends AggregateFunction<num> {
  SumAggregate(super.driver, super.tableName);

  @override
  String get name => 'SUM';
}

class CountAggregate extends AggregateFunction<num> {
  CountAggregate(super.driver, super.tableName);

  @override
  String get name => 'COUNT';
}

class AverageAggregate extends AggregateFunction<num> {
  AverageAggregate(super.driver, super.tableName);

  @override
  String get name => 'AVG';
}

class MaxAggregate extends AggregateFunction<num> {
  MaxAggregate(super.driver, super.tableName);

  @override
  String get name => 'MAX';
}

class MinAggregate extends AggregateFunction<num> {
  MinAggregate(super.driver, super.tableName);

  @override
  String get name => 'MIN';
}

class TotalAggregate extends AggregateFunction<num> {
  TotalAggregate(super.driver, super.tableName);

  @override
  String get name => 'TOTAL';
}

class ConcatAggregate<T> extends AggregateFunction<T> {
  ConcatAggregate(super.driver, super.tableName);

  @override
  String get name => 'GROUP_CONCAT';
}
