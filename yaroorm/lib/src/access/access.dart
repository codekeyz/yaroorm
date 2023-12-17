import '../database/driver/driver.dart';
import '../database/entity.dart';
import '../reflection/entity_helpers.dart';

part 'operations/query.dart';
part 'primitives/where.dart';

abstract class PrimitiveSerializer {
  String acceptReadQuery(ReadQuery query);

  String acceptUpdateQuery(UpdateQuery query);

  String acceptWhereClause(WhereClause clause);

  String acceptSelect(List<String> fields);

  String acceptOrderBy(List<OrderBy> orderBys);

  String acceptLimit(int limit);

  dynamic acceptDartValue(dynamic value);

  String get terminator;
}

mixin FindOperation<Model extends Entity> {
  Future<Model?> findOne();

  Future<List<Model>> findMany();
}

mixin UpdateOperation<Model extends Entity> {
  Future<void> _update(WhereClause<Model> where, Map<String, dynamic> values);
}

mixin InsertOperation<Model extends Entity> {
  Future<Model> insert(Model model);
}

mixin LimitOperation<ReturnType> {
  ReturnType limit(int limit);
}

typedef OrderBy = ({String field, OrderByDirection direction});

mixin OrderByOperation<ReturnType> {
  ReturnType orderBy(String field, OrderByDirection direction);
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
        UpdateOperation<Model>,
        OrderByOperation<ReadQuery<Model>>,
        LimitOperation<Future<List<Model>>> {
  late final Set<String> fieldSelections;
  late final Set<OrderBy> orderByProps;

  late WhereClause<Model>? _whereClause;
  late int? _limit;

  ReadQuery(super.tableName, super.driver)
      : fieldSelections = {},
        orderByProps = {},
        _whereClause = null,
        _limit = null;

  factory ReadQuery.make(String tableName, DatabaseDriver driver) =>
      _ReadQueryImpl(tableName, driver);

  WhereClause<Model>? get whereClause => _whereClause;

  int? get limitValue => _limit;

  WhereClause<Model> where<Value>(String field, String condition, Value value);

  @override
  String get statement => driver.serializer.acceptReadQuery(this);
}

class UpdateQuery<Model extends Entity> extends BaseQuery {
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
