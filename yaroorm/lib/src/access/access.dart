import '../database/driver/driver.dart';
import '../database/entity.dart';
import '../reflection/entity_helpers.dart';

part 'operations/query.dart';
part 'primitives/where.dart';

mixin FindOperation<Model extends Entity> {
  Future<Model?> findOne();

  Future<List<Model>> findMany();
}

mixin UpdateOperation<Model extends Entity> {
  Future<void> _update(WhereClause<Model> where, Map<String, dynamic> values);
}

mixin DeleteOperation<Model extends Entity> {
  Future<void> _delete(WhereClause<Model> where);
}

mixin InsertOperation<Model extends Entity> {
  Future<Model> insert(Model model);
}

mixin LimitOperation<ReturnType> {
  ReturnType take(int limit);
}

typedef OrderBy = ({String field, OrderByDirection direction});

mixin OrderByOperation<ReturnType> {
  ReturnType orderBy(String field, OrderByDirection direction);
}

abstract interface class QueryBase {
  final String tableName;
  final DatabaseDriver driver;

  QueryBase(this.tableName, this.driver);

  String get statement;
}

abstract class Query<Model extends Entity> extends QueryBase
    with
        FindOperation<Model>,
        InsertOperation<Model>,
        UpdateOperation<Model>,
        DeleteOperation<Model>,
        OrderByOperation<Query<Model>>,
        LimitOperation<Future<List<Model>>> {
  late final Set<String> fieldSelections;
  late final Set<OrderBy> orderByProps;

  late WhereClause<Model>? _whereClause;
  late int? _limit;

  Query(super.tableName, super.driver)
      : fieldSelections = {},
        orderByProps = {},
        _whereClause = null,
        _limit = null;

  factory Query.make(String tableName, DatabaseDriver driver) =>
      _QueryImpl(tableName, driver);

  WhereClause<Model>? get whereClause => _whereClause;

  int? get limitValue => _limit;

  WhereClause<Model> where<Value>(String field, String condition, Value value);

  @override
  String get statement => driver.serializer.acceptReadQuery(this);
}

class UpdateQuery<Model extends Entity> extends QueryBase {
  final WhereClause<Model> whereClause;
  final Map<String, dynamic> values;

  UpdateQuery(
    super.tableName,
    super.driver, {
    required this.whereClause,
    required this.values,
  });

  @override
  String get statement => driver.serializer.acceptUpdateQuery(this);
}

class DeleteQuery<Model extends Entity> extends QueryBase {
  final WhereClause<Model> whereClause;

  DeleteQuery(
    super.tableName,
    super.driver, {
    required this.whereClause,
  });

  @override
  String get statement => driver.serializer.acceptDeleteQuery(this);
}
