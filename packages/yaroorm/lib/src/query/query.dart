import 'package:meta/meta.dart';
import 'package:yaroorm/src/query/aggregates.dart';
import 'package:yaroorm/yaroorm.dart';

import '../primitives/where.dart';

part 'query_impl.dart';

mixin ReadOperation<Result> {
  Future<Result?> get([Object id]);

  Future<List<Result>> all({int? limit});

  Future<List<Result>> take(int limit);
}

mixin FindOperation<Result> {
  Future<Result?> findOne();

  Future<List<Result>> findMany();
}

mixin InsertOperation {
  Future<PrimaryKeyKey> insert<PrimaryKeyKey>(Map<String, dynamic> data);

  Future<void> insertMany(List<Map<String, dynamic>> values);
}

mixin LimitOperation<ReturnType> {
  Future<List<ReturnType>> take(int limit);
}

mixin UpdateOperation<Result> {
  UpdateQuery update({
    required WhereClause<Result> Function(Query query) where,
    required Map<String, dynamic> values,
  });
}

mixin DeleteOperation<Result> {
  DeleteQuery delete(WhereClause<Result> Function(Query query) where);
}

typedef OrderBy = ({String field, OrderByDirection direction});

mixin OrderByOperation<ReturnType> {
  ReturnType orderByAsc(String field);

  ReturnType orderByDesc(String field);
}

sealed class QueryBase<Owner> {
  final String tableName;

  String? database;

  DriverContract? _queryDriver;

  DriverContract get runner {
    if (_queryDriver == null) {
      throw StateError(
          'Driver not set for query. Make sure you supply a driver using .driver()');
    }
    return _queryDriver!;
  }

  Owner driver(DriverContract driver) {
    _queryDriver = driver;
    return this as Owner;
  }

  Future<void> execute();

  QueryBase(this.tableName);

  String get statement;
}

abstract interface class Query<EntityType> extends QueryBase<Query<EntityType>>
    with
        ReadOperation<EntityType>,
        WhereOperation<EntityType>,
        LimitOperation<EntityType>,
        OrderByOperation<Query<EntityType>>,
        InsertOperation,
        DeleteOperation<EntityType>,
        UpdateOperation<EntityType>,
        AggregateOperation {
  final Set<String> fieldSelections;
  final Set<OrderBy> orderByProps;
  final List<WhereClause<EntityType>> whereClauses;

  static final Map<Type, DBEntity> _typedata = {};

  // ignore: prefer_final_fields
  int? _limit;

  int? get limit => _limit;

  Query(super.tableName)
      : fieldSelections = {},
        orderByProps = {},
        whereClauses = [],
        _limit = null;

  static Query<Model> table<Model extends Entity>([String? tableName]) {
    if (Model != Entity && Model != dynamic) {
      tableName ??= getEntityTableName<Model>();
    }
    assert(tableName != null, 'Either provide Entity Type or tableName');
    return QueryImpl<Model>(tableName!);
  }

  Query<EntityType> select(List<String> selections) {
    fieldSelections.addAll(selections);
    return this;
  }

  @override
  DeleteQuery delete(
    WhereClause<EntityType> Function(Query<EntityType> query) where,
  ) {
    return DeleteQuery(
      tableName,
      whereClause: where(this),
    ).driver(runner);
  }

  @override
  UpdateQuery update({
    required WhereClause<EntityType> Function(Query<EntityType> query) where,
    required Map<String, dynamic> values,
  }) {
    return UpdateQuery(
      tableName,
      whereClause: where(this),
      data: values,
    ).driver(runner);
  }

  static void addTypeDef<T extends Entity>(DBEntity entity) {
    var type = T;
    if (type == Entity) type = entity.dartType;
    if (type == Entity) throw Exception();
    _typedata[type] = entity;
  }

  @internal
  static DBEntity getEntity<T extends Entity>({Type? type}) {
    type ??= T;
    return _typedata.containsKey(type)
        ? _typedata[type]!
        : throw Exception('Type Data not found for $type');
  }
}

mixin AggregateOperation {
  Future<int> count({String? field, bool distinct = false});

  Future<num> average(String field);

  Future<num> sum(String field);

  Future<num> max(String field);

  Future<num> min(String field);

  Future<String> groupConcat(String field, String separator);
}

@protected
class UpdateQuery extends QueryBase<UpdateQuery> {
  final WhereClause whereClause;
  final Map<String, dynamic> data;

  UpdateQuery(super.tableName, {required this.whereClause, required this.data});

  @override
  String get statement => runner.serializer.acceptUpdateQuery(this);

  @override
  Future<void> execute() => runner.update(this);
}

class InsertQuery extends QueryBase<InsertQuery> {
  final Map<String, dynamic> data;

  InsertQuery(super.tableName, {required this.data});

  @override
  Future<dynamic> execute() => runner.insert(this);

  @override
  String get statement => runner.serializer.acceptInsertQuery(this);
}

class InsertManyQuery extends QueryBase<InsertManyQuery> {
  final List<Map<String, dynamic>> values;

  InsertManyQuery(super.tableName, {required this.values});

  @override
  String get statement => runner.serializer.acceptInsertManyQuery(this);

  @override
  Future<dynamic> execute() => runner.insertMany(this);
}

@protected
class DeleteQuery extends QueryBase<DeleteQuery> {
  final WhereClause whereClause;

  DeleteQuery(super.tableName, {required this.whereClause});

  @override
  String get statement => runner.serializer.acceptDeleteQuery(this);

  @override
  Future<void> execute() => runner.delete(this);
}
