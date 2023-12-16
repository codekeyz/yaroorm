import '../database/driver/driver.dart';
import '../database/entity.dart';
import '../reflection/entity_helpers.dart';

part 'operations/query.dart';
part 'operations/update.dart';
part 'primitives/where.dart';

abstract class PrimitiveSerializer {
  String acceptQuery(ReadQuery query);

  String acceptUpdate(UpdateQuery update);

  String acceptWhereClause(WhereClause clause);

  String acceptSelect(List<String> fields);

  String acceptOrderBy(List<OrderBy> orderBys);

  String acceptLimit(int limit);

  String get terminator;
}

mixin FindOperation<Model extends Entity> {
  Future<Model?> findOne();

  Future<List<Model>> findMany();
}

mixin LimitOperation<ReturnType> {
  ReturnType limit(int limit);
}

typedef OrderBy = ({String field, OrderByDirection direction});

mixin OrderByOperation<ReturnType> {
  ReturnType orderBy(String field, OrderByDirection direction);
}

mixin InsertOperation<Model extends Entity> {
  Future<Model> insert(Model model);
}

abstract interface class BaseOperation {
  final String tableName;
  final DatabaseDriver driver;

  BaseOperation(this.tableName, this.driver);

  String get statement;
}

abstract interface class ReadOperation<Model extends Entity>
    extends BaseOperation
    with
        FindOperation<Model>,
        InsertOperation<Model>,
        OrderByOperation<ReadQuery<Model>>,
        LimitOperation<Future<List<Model>>> {
  ReadOperation(super.tableName, super.driver);

  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  );
}

abstract interface class UpdateOperation<Model extends Entity>
    extends BaseOperation {
  UpdateOperation(super.tableName, super.driver);

  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  );
}
