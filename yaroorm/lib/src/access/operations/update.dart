part of '../access.dart';

final class UpdateQuery<Model extends Entity> extends UpdateOperation<Model> {
  UpdateQuery(super.tableName, super.driver);

  @override
  String get statement => driver.serializer.acceptUpdate(this);

  @override
  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  ) {
    throw UnimplementedError();
  }
}
