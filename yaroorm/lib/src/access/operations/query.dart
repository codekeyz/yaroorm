part of '../access.dart';

enum OrderByDirection { asc, desc }

final class _ReadQueryImpl<Model extends Entity> extends ReadQuery<Model> {
  _ReadQueryImpl(String tableName, DatabaseDriver driver)
      : super(tableName, driver);

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
  ReadQuery<Model> orderBy(String field, OrderByDirection direction) {
    orderByProps.add((field: field, direction: direction));
    return this;
  }
}
