part of 'query.dart';

mixin FindOneOperation<Model extends Entity> {
  Future<Model?> findOne();
}

mixin LimitOperation<ReturnType> {
  ReturnType limit(int limit);
}

typedef OrderBy = ({String field, OrderByDirection direction});

mixin OrderByOperation<ReturnType> {
  ReturnType orderBy(String field, OrderByDirection direction);
}

mixin InsertOperation<Model extends Entity> {
  Future<Model> insert(Model entity);
}

abstract interface class EntityOperations<Model extends Entity>
    with
        InsertOperation<Model>,
        FindOneOperation<Model>,
        LimitOperation<Future<List<Model>>>,
        OrderByOperation<EntityTableInterface<Model>> {
  WhereClause<Model> where<Value>(String field, String condition, Value value);

  Future<List<Model>> all();
}

abstract class QueryPrimitiveSerializer {
  String acceptWhereClause(WhereClause clause);

  String acceptQuery(EntityTableInterface query);

  String acceptSelect(List<String> fields);

  String acceptOrderBy(List<OrderBy> orderBys);

  String acceptLimit(int limit);

  String get terminator;
}
