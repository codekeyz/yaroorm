part of '../access.dart';

enum OrderByDirection { asc, desc }

final class _QueryImpl<Model extends Entity> extends Query<Model> {
  _QueryImpl(String tableName, DatabaseDriver driver)
      : super(tableName, driver);

  @override
  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  ) {
    return _whereClause = WhereClause<Model>(
      (field: field, condition: condition, value: value),
      this,
    );
  }

  @override
  Query<Model> orderBy(String field, OrderByDirection direction) {
    orderByProps.add((field: field, direction: direction));
    return this;
  }

  @override
  Future<Model?> findOne() async {
    final results = await this.limit(1);
    return results.firstOrNull;
  }

  @override
  Future<List<Model>> findMany() async {
    final results = await driver.query(this);
    if (results.isEmpty) return <Model>[];
    return results.map<Model>(jsonToEntity<Model>).toList();
  }

  @override
  Future<Model> insert(Model model) async {
    if (model.enableTimestamps) {
      model.createdAt = model.updatedAt = DateTime.now().toUtc();
    }
    final dataMap = model.toJson()..remove('id');
    final recordId = await driver.insert(tableName, dataMap);
    return model..id = model.id.withKey(recordId);
  }

  @override
  Future<List<Model>> limit(int limit) async {
    _limit = limit;
    final results = await driver.query(this);
    if (results.isEmpty) return <Model>[];
    return results.map<Model>(jsonToEntity<Model>).toList();
  }

  @override
  Future<void> _update(
    WhereClause<Model> where,
    Map<String, dynamic> values,
  ) async {
    final query =
        UpdateQuery(tableName, driver, whereClause: where, values: values);
    await driver.update(query);
  }

  @override
  Future<void> _delete(WhereClause<Model> where) {
    final query = DeleteQuery(tableName, driver, whereClause: where);
    throw UnimplementedError();
  }
}
