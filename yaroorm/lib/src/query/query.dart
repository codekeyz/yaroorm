import '../database/driver/driver.dart';
import '../reflection/reflection.dart';
import 'primitives.dart';

enum OrderByDirection { asc, desc }

@entity
abstract class Entity {}

final class RecordQueryInterface<Model extends Entity> implements TableOperations<Model> {
  final DatabaseDriver? _driver;

  final String tableName;
  final Set<String> fieldSelections = {};
  final Set<OrderBy> orderByProps = {};

  WhereClause? whereClause;

  RecordQueryInterface(this.tableName, {DatabaseDriver? driver}) : _driver = driver;

  @override
  RecordQueryInterface<Model> select(List<String> fields) {
    fieldSelections.addAll(fields);
    return this;
  }

  @override
  RecordQueryInterface<Model> orderBy(String field, OrderByDirection direction) {
    orderByProps.add((field: field, order: direction));
    return this;
  }

  @override
  Future<Model> get({DatabaseDriver? driver}) async {
    driver ??= _driver;

    throw Exception('Hello World');
  }

  String get rawQuery {
    if (_driver == null) {
      throw Exception('Cannot resolve rawQuery. No driver provided');
    }
    return _driver!.querySerializer.acceptQuery(this);
  }

  @override
  WhereClause<Model> where<Value>(String field, String condition, Value value) {
    if (whereClause != null) throw Exception('Only one where clause is supported');
    return whereClause = WhereClause<Model>(
      (field: field, condition: condition, value: value),
      this,
    );
  }
}
