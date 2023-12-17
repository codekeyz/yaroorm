part of '../access.dart';

enum OrderByDirection { asc, desc }

final class _QueryImpl extends Query {
  _QueryImpl(String tableName, DatabaseDriver driver)
      : super(tableName, driver);

  @override
  WhereClause where<Value>(String field, String condition, Value value) {
    return _whereClause = WhereClause(
      (field: field, condition: condition, value: value),
      this,
    );
  }

  @override
  Query orderBy(String field, OrderByDirection direction) {
    orderByProps.add((field: field, direction: direction));
    return this;
  }

  @override
  Future<T> insert<T extends Entity>(T model) async {
    if (model.enableTimestamps) {
      model.createdAt = model.updatedAt = DateTime.now().toUtc();
    }
    final dataMap = model.toJson()..remove('id');
    final recordId = await driver.insert(tableName, dataMap);
    return model..id = model.id.withKey(recordId);
  }

  @override
  Future<void> _update(WhereClause where, Map<String, dynamic> values) async {
    final query =
        UpdateQuery(tableName, driver, whereClause: where, values: values);
    await driver.update(query);
  }

  @override
  Future<void> _delete(WhereClause where) async {
    final query = DeleteQuery(tableName, driver, whereClause: where);
    await driver.delete(query);
  }

  @override
  Future<List<T>> findMany<T>() async {
    final results = await driver.query(this);
    if (results.isEmpty) return <T>[];
    if (T == dynamic) return results as dynamic;
    return results.map(jsonToEntity<T>).toList();
  }

  @override
  Future<List<T>> take<T>(int limit) async {
    _limit = limit;
    final results = await driver.query(this);
    if (results.isEmpty) return <T>[];
    if (T == dynamic) return results as dynamic;
    return results.map(jsonToEntity<T>).toList();
  }

  @override
  Future<T?> findOne<T>() async {
    final results = await take<T>(1);
    return results.firstOrNull;
  }
}
