import 'package:meta/meta.dart';

import '../_reflection/entity_helpers.dart';
import '../database/driver/driver.dart';

part 'operations/query.dart';
part 'primitives/where.dart';
part 'primitives/where_impl.dart';

mixin ReadOperation {
  Future<T?> get<T>();

  Future<List<T>> all<T>();
}

mixin FindOperation {
  Future<T?> findOne<T>();

  Future<List<T>> findMany<T>();
}

mixin InsertOperation {
  InsertQuery insert(Map<String, dynamic> values);

  InsertManyQuery insertAll(List<Map<String, dynamic>> values);
}

mixin LimitOperation<ReturnType> {
  ReturnType take<T>(int limit);
}

mixin UpdateOperation {
  UpdateQuery update(Map<String, dynamic> values);
}

mixin DeleteOperation {
  DeleteQuery delete();
}

typedef OrderBy = ({String field, OrderByDirection direction});

mixin OrderByOperation<ReturnType> {
  ReturnType orderByAsc(String field);

  ReturnType orderByDesc(String field);
}

abstract interface class QueryBase<Owner> {
  final String tableName;

  DriverAble? _queryDriver;

  DriverAble get queryDriver {
    if (_queryDriver == null) {
      throw StateError('Driver not set for query. Make sure you supply a driver using .driver()');
    }
    return _queryDriver!;
  }

  Owner driver(DriverAble driver) {
    _queryDriver = driver;
    return this as Owner;
  }

  Future<void> exec();

  QueryBase(this.tableName);

  String get statement;
}

abstract class Query extends QueryBase<Query>
    with ReadOperation, WhereOperation, LimitOperation, InsertOperation, OrderByOperation<Query> {
  late final Set<String> fieldSelections;
  late final Set<OrderBy> orderByProps;
  late final List<WhereClause> whereClauses;

  late int? _limit;

  Query(super.tableName)
      : fieldSelections = {},
        orderByProps = {},
        whereClauses = [],
        _limit = null;

  factory Query.table(String tableName) => _QueryImpl(tableName);

  int? get limit => _limit;

  @override
  Future<List<T>> take<T>(int limit);

  @override
  String get statement => queryDriver.serializer.acceptReadQuery(this);
}

@protected
class UpdateQuery extends QueryBase<UpdateQuery> {
  final WhereClause whereClause;
  final Map<String, dynamic> values;

  UpdateQuery(super.tableName, {required this.whereClause, required this.values});

  @override
  String get statement => queryDriver.serializer.acceptUpdateQuery(this);

  @override
  Future<void> exec() => queryDriver.update(this);
}

class InsertQuery extends QueryBase<InsertQuery> {
  final Map<String, dynamic> values;

  InsertQuery(super.tableName, {required this.values});

  @override
  Future<dynamic> exec() => queryDriver.insert(this);

  @override
  String get statement => queryDriver.serializer.acceptInsertQuery(this);
}

class InsertManyQuery extends QueryBase<InsertManyQuery> {
  final List<Map<String, dynamic>> values;

  InsertManyQuery(super.tableName, {required this.values});

  @override
  String get statement => queryDriver.serializer.acceptInsertManyQuery(this);

  @override
  Future<dynamic> exec() => queryDriver.insertMany(this);
}

@protected
class DeleteQuery extends QueryBase<DeleteQuery> {
  final WhereClause whereClause;

  DeleteQuery(super.tableName, {required this.whereClause});

  @override
  String get statement => queryDriver.serializer.acceptDeleteQuery(this);

  @override
  Future<void> exec() => queryDriver.delete(this);
}
