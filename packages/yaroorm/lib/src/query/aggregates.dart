import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';

abstract interface class AggregateFunction<T> {
  final List<String> selections;
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
    final result = await driver.rawQuery(statement);
    return result[0] as T;
  }

  String get statement => driver.serializer.acceptAggregate(this);
}

class SumAggregate extends AggregateFunction<num> {
  SumAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'SUM';
}

class CountAggregate extends AggregateFunction<int> {
  CountAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'COUNT';
}

class AverageAggregate extends AggregateFunction<num> {
  AverageAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'AVG';
}

class MaxAggregate extends AggregateFunction<num> {
  MaxAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'MAX';
}

class MinAggregate extends AggregateFunction<num> {
  MinAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'MIN';
}

class ConcatAggregate extends AggregateFunction<String> {
  ConcatAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'CONCAT';
}
