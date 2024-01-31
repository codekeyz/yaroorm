import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';
import 'package:yaroorm/src/query/query.dart';

abstract interface class AggregateFunction<T> {
  final Set<String> selections;
  final WhereClause? where;
  final DriverContract driver;

  String get name;

  const AggregateFunction(
    this.driver, {
    this.selections = const {'*'},
    this.where,
  });

  Future<T> get() async {
    final statement = driver.serializer.acceptAggregate(this);
    return await driver.execute(statement) as T;
  }
}

class SumAggregate extends AggregateFunction<num> {
  SumAggregate(super.driver);

  @override
  String get name => 'SUM';
}

class CountAggregate extends AggregateFunction<num> {
  CountAggregate(super.driver);

  @override
  String get name => 'COUNT';
}

class AverageAggregate extends AggregateFunction<num> {
  AverageAggregate(super.driver);

  @override
  String get name => 'AVG';
}

class MaxAggregate extends AggregateFunction<num> {
  MaxAggregate(super.driver);

  @override
  String get name => 'MAX';
}

class MinAggregate extends AggregateFunction<num> {
  MinAggregate(super.driver);

  @override
  String get name => 'MIN';
}

class TotalAggregate extends AggregateFunction<num> {
  TotalAggregate(super.driver);

  @override
  String get name => 'TOTAL';
}

class GroupConcatAggregate extends AggregateFunction<num> {
  GroupConcatAggregate(super.driver);

  @override
  String get name => 'GROUP_CONCAT';
}
