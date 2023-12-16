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

abstract interface class BaseQuery {
  final String tableName;
  final DatabaseDriver driver;

  BaseQuery(this.tableName, this.driver);

  String get statement;
}

abstract class ReadQuery<Model extends Entity> extends BaseQuery
    with
        FindOperation<Model>,
        InsertOperation<Model>,
        OrderByOperation<ReadQuery<Model>>,
        LimitOperation<Future<List<Model>>> {
  late final Set<String> fieldSelections;
  late final Set<OrderBy> orderByProps;

  late WhereClause? _whereClause;
  late int? _limit;

  ReadQuery(super.tableName, super.driver)
      : fieldSelections = {},
        orderByProps = {},
        _whereClause = null,
        _limit = null;

  factory ReadQuery.make(String tableName, DatabaseDriver driver) =>
      _ReadQueryImpl(tableName, driver);

  WhereClause? get whereClause => _whereClause;

  int? get limitValue => _limit;

  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  );

  @override
  String get statement => driver.serializer.acceptQuery(this);
}

abstract interface class UpdateQuery<Model extends Entity> extends BaseQuery {
  UpdateQuery(super.tableName, super.driver);

  factory UpdateQuery.make(String tableName, DatabaseDriver driver) =>
      _UpdateQueryImpl(tableName, driver);

  WhereClause<Model> where<Value>(
    String field,
    String condition,
    Value value,
  );

  @override
  String get statement => driver.serializer.acceptUpdate(this);
}
