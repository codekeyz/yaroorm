import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/primitives/where.dart';
import 'package:yaroorm/src/query/query.dart';

abstract interface class AggregateFunction<T> {
  final List<String> selections;
  final WhereClause? where;
  final DatabaseDriver driver;

  String get name;

  const AggregateFunction(
    this.driver, {
    this.selections = const ['*'],
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
