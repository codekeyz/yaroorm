part of '../access.dart';

final class _UpdateQueryImpl<Model extends Entity> extends UpdateQuery<Model> {
  _UpdateQueryImpl(super.tableName, super.driver);

  @override
  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  ) {
    throw UnimplementedError();
  }
}
