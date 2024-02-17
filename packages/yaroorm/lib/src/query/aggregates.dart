import '../database/driver/driver.dart';
import '../primitives/where.dart';
import 'query.dart';

sealed class AggregateFunction<T> {
  final List<String> selections;
  final List<WhereClause> whereClauses;
  final String tableName;
  final DriverContract driver;

  List<String> get arguments {
    if (selections.isEmpty) return ['*'];
    return selections;
  }

  String get name;

  const AggregateFunction(
    this.driver,
    this.tableName, {
    this.selections = const [],
    this.whereClauses = const [],
  });

  AggregateFunction._init(Query query, String? field)
      : driver = query.runner,
        tableName = query.tableName,
        whereClauses = query.whereClauses,
        selections = field == null ? const [] : [field],
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

class CountAggregate extends AggregateFunction<int> {
  CountAggregate(super.query, super.field) : super._init();

  @override
  String get name => 'COUNT';
}

class SumAggregate extends AggregateFunction<num> {
  SumAggregate(super.query, String super.field) : super._init();

  @override
  String get name => 'SUM';
}

class AverageAggregate extends AggregateFunction<num> {
  AverageAggregate(super.query, String super.field) : super._init();

  @override
  String get name => 'AVG';
}

class MaxAggregate extends AggregateFunction<num> {
  MaxAggregate(super.query, String super.field) : super._init();

  @override
  String get name => 'MAX';
}

class MinAggregate extends AggregateFunction<num> {
  MinAggregate(super.query, String super.field) : super._init();

  @override
  String get name => 'MIN';
}

class GroupConcatAggregate extends AggregateFunction<String> {
  final String separator;

  GroupConcatAggregate(super.query, String super.field, this.separator)
      : super._init();

  @override
  List<String> get arguments {
    final separatorStr = "'$separator'";

    if (driver.type == DatabaseDriverType.pgsql) {
      return ['ARRAY_AGG(${selections.first})', separatorStr];
    }

    return [...super.arguments, separatorStr];
  }

  @override
  String get name {
    if (driver.type == DatabaseDriverType.pgsql) return 'ARRAY_TO_STRING';
    return 'GROUP_CONCAT';
  }
}
