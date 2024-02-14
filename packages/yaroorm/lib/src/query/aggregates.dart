import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';
import 'package:yaroorm/src/query/query.dart';

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

  Future<QueryResult> get() async {
    final statement = driver.serializer.acceptAggregate(this);
    var result = await driver.rawQuery(statement);
    return result[0];
  }

  String get statement => driver.serializer.acceptAggregate(this);
}

class SumAggregate<T> extends AggregateFunction {
  SumAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'SUM';
}

class CountAggregate<T> extends AggregateFunction {
  CountAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'COUNT';
}

class AverageAggregate<T> extends AggregateFunction {
  AverageAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'AVG';
}

class MaxAggregate<T> extends AggregateFunction {
  MaxAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'MAX';
}

class MinAggregate<T> extends AggregateFunction {
  MinAggregate(
    super.driver,
    super.tableName,
    super.selections, {
    super.where,
  });

  @override
  String get name => 'MIN';
}

class ConcatAggregate<T> extends AggregateFunction {
  ConcatAggregate(super.driver, super.tableName, super.selections);

  @override
  String get name => 'CONCAT';
}
