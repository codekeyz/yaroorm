part of '../access.dart';

class UpdateQuery<Model extends Entity> extends UpdateOperation {
  UpdateQuery(super.tableName, super.driver);

  @override
  WhereClause<Entity> where<Value>(
    String field,
    String condition,
    Value value,
  ) {
    throw UnimplementedError();
  }

  @override
  String get statement => driver.serializer.acceptUpdate(this);
}
