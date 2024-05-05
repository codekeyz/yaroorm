import 'dart:collection';

import 'package:meta/meta.dart';

import '../database/driver/driver.dart';
import '../database/entity/entity.dart' hide value;
import '../reflection.dart';
import 'aggregates.dart';

part '../primitives/where.dart';

enum OrderDirection { asc, desc }

abstract class CreateEntity<T extends Entity<T>> {
  const CreateEntity();
  @internal
  Map<Symbol, dynamic> get toMap;
}

abstract class UpdateEntity<T extends Entity<T>> {
  const UpdateEntity();
  @internal
  Map<Symbol, dynamic> get toMap;
}

mixin ReadOperation<Result extends Entity<Result>> {
  Future<Result?> findOne({
    WhereBuilder<Result>? where,
  });

  Future<List<Result>> findMany({
    WhereBuilder<Result>? where,
    List<OrderBy<Result>> orderBy,
    int? limit,
    int? offset,
  });
}

mixin InsertOperation<T extends Entity<T>> {
  Future<T> insert(CreateEntity<T> data);
  Future<void> insertMany(List<CreateEntity<T>> datas);
}

mixin UpdateOperation<Result extends Entity<Result>> {
  UpdateQuery update({
    required WhereBuilder<Result> where,
    required UpdateEntity<Result> update,
  });
}

mixin RelationsOperation<T extends Entity<T>> {
  withRelations(List<Join<T, Entity, EntityRelation<T, Entity>>> Function(JoinBuilder<T> builder) builder) {
    return this;
  }
}

mixin LimitOperation<ReturnType> {
  Future<List<ReturnType>> take(int limit);
}

abstract class OrderBy<T extends Entity<T>> {
  final String field;
  final OrderDirection direction;

  const OrderBy(this.field, this.direction);
}

sealed class QueryBase<Owner> {
  final String tableName;
  final String? database;

  final Query $query;

  DriverContract get runner => $query.runner;

  Future<void> execute();

  QueryBase(this.$query)
      : tableName = $query.tableName,
        database = $query.database;

  String get statement;
}

final class Query<T extends Entity<T>>
    with ReadOperation<T>, InsertOperation<T>, UpdateOperation<T>, AggregateOperation, RelationsOperation<T> {
  final DBEntity<T> entity;
  final String? database;
  final List<Join> _joins;

  late final String tableName;

  DriverContract? _queryDriver;

  Map<Type, EntityTypeConverter> get converters => combineConverters(entity.converters, runner.typeconverters);

  static final Map<Type, DBEntity> _typedatas = {};

  Query._({String? tableName, this.database})
      : entity = Query.getEntity<T>(),
        _joins = [] {
    this.tableName = tableName ?? entity.tableName;
  }

  DriverContract get runner {
    if (_queryDriver == null) {
      throw StateError('Driver not set for query. Make sure you supply a driver using .driver()');
    }
    return _queryDriver!;
  }

  Query<T> driver(DriverContract driver) {
    _queryDriver = driver;
    return this;
  }

  static Query<Model> table<Model extends Entity<Model>>([String? tableName, String? database]) {
    if (Model == Entity || Model == dynamic) {
      throw UnsupportedError('Query cannot receive Entity or dynamic as Type');
    }
    return Query<Model>._(tableName: tableName, database: database);
  }

  static void addTypeDef<T extends Entity<T>>(DBEntity<T> entity) {
    var type = T;
    if (type == Entity) type = entity.dartType;
    if (type == Entity) throw Exception();
    _typedatas[type] = entity;
  }

  @internal
  static DBEntity<T> getEntity<T extends Entity<T>>({Type? type}) {
    type ??= T;
    if (!_typedatas.containsKey(type)) {
      throw Exception('Type Data not found for $type');
    }
    return _typedatas[type]! as dynamic;
  }

  ReadQuery<T> where(WhereBuilder<T> builder) {
    final whereClause = builder.call(WhereClauseBuilder<T>());
    return ReadQuery<T>._(this, whereClause: whereClause);
  }

  UnmodifiableMapView<String, dynamic> _prepareCreate(CreateEntity<T> data) {
    final dataMap = data.toMap;
    if (entity.timestampsEnabled) {
      final now = DateTime.now();
      final createdAtField = entity.createdAtField;
      final updatedAtField = entity.updatedAtField;

      if (createdAtField != null) {
        dataMap[createdAtField.dartName] = now;
      }

      if (updatedAtField != null) {
        dataMap[updatedAtField.dartName] = now;
      }
    }
    return entityMapToDbData<T>(dataMap, converters);
  }

  @override
  Future<T> insert(CreateEntity<T> data) async {
    final dataMap = _prepareCreate(data);
    final recordId = await runner.insert(
      InsertQuery(
        this,
        data: dataMap,
        primaryKey: entity.primaryKey.columnName,
      ),
    );

    return (await findOne(where: (q) => q.$equal(entity.primaryKey.columnName, recordId)))!;
  }

  @override
  Future<void> insertMany(List<CreateEntity<T>> datas) async {
    final dataMap = datas.map(_prepareCreate).toList();
    await runner.insertMany(
      InsertManyQuery(
        this,
        values: dataMap,
        primaryKey: entity.primaryKey.columnName,
      ),
    );
  }

  @override
  Future<List<T>> findMany({
    WhereBuilder<T>? where,
    List<OrderBy<T>>? orderBy,
    int? limit,
    int? offset,
  }) async {
    final whereClause = where?.call(WhereClauseBuilder<T>());
    final readQ = ReadQuery._(
      this,
      limit: limit,
      offset: offset,
      whereClause: whereClause,
      orderByProps: orderBy?.toSet(),
      joins: _joins,
      groupBys: [entity.primaryKey.columnName],
    );

    final results = await runner.query(readQ);
    if (results.isEmpty) return <T>[];
    return results.map(_wrapRawResult).toList();
  }

  @override
  Future<T?> findOne({WhereBuilder<T>? where}) async {
    final whereClause = where?.call(WhereClauseBuilder<T>());
    final readQ = ReadQuery._(this, limit: 1, whereClause: whereClause, joins: _joins);
    final results = await runner.query(readQ);
    if (results.isEmpty) return null;
    return results.map(_wrapRawResult).first;
  }

  @override
  UpdateQuery update({
    required WhereBuilder<T> where,
    required UpdateEntity<T> update,
  }) {
    final values = update.toMap;
    final whereClause = where.call(WhereClauseBuilder<T>());

    if (entity.timestampsEnabled) {
      final now = DateTime.now();
      final updatedAtField = entity.updatedAtField;
      if (updatedAtField != null) {
        values[updatedAtField.dartName] = now;
      }
    }

    final dataToDbD = entityMapToDbData<T>(
      values,
      converters,
      onlyPropertiesPassed: true,
    );

    return UpdateQuery(this, whereClause: whereClause, data: dataToDbD);
  }

  /// [T] is the expected type passed to [Query] via Query<T>
  T _wrapRawResult(Map<String, dynamic> result) {
    final Map<Type, Map<String, dynamic>> joinResults = {};
    for (final join in _joins) {
      final entries = result.entries
          .where((e) => e.key.startsWith('${join.resultKey}.'))
          .map((e) => MapEntry<String, dynamic>(e.key.replaceFirst('${join.resultKey}.', '').trim(), e.value));
      if (entries.every((e) => e.value == null)) {
        joinResults[join.key] = {};
      } else {
        joinResults[join.key] = {}..addEntries(entries);
      }
    }

    return serializedPropsToEntity<T>(
      result,
      entity,
      converters,
    ).withRelationsData(joinResults).withDriver(runner) as T;
  }

  ReadQuery<T> get _readQuery => ReadQuery<T>._(this);

  @override
  Future<num> average(String field) {
    return AverageAggregate(_readQuery, field).get();
  }

  @override
  Future<int> count({String? field, bool distinct = false}) {
    return CountAggregate(_readQuery, field, distinct).get();
  }

  @override
  Future<String> groupConcat(String field, String separator) {
    return GroupConcatAggregate(_readQuery, field, separator).get();
  }

  @override
  Future<num> max(String field) => MaxAggregate(_readQuery, field).get();

  @override
  Future<num> min(String field) => MinAggregate(_readQuery, field).get();

  @override
  Future<num> sum(String field) => SumAggregate(_readQuery, field).get();

  @override
  Query<T> withRelations(List<Join<T, Entity, EntityRelation<T, Entity>>> Function(JoinBuilder<T> builder) builder) {
    _joins
      ..clear()
      ..addAll(builder.call(_JoinBuilderImpl<T>()));
    return this;
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
final class UpdateQuery extends QueryBase<UpdateQuery> {
  final WhereClause whereClause;
  final Map<String, dynamic> data;

  UpdateQuery(super.tableName, {required this.whereClause, required this.data});

  @override
  String get statement => $query.runner.serializer.acceptUpdateQuery(this);

  @override
  Future<void> execute() => runner.update(this);
}

final class ReadQuery<T extends Entity<T>> extends QueryBase<ReadQuery> with AggregateOperation, RelationsOperation<T> {
  final Set<String> fieldSelections;
  final Set<OrderBy<T>>? orderByProps;
  final WhereClause? whereClause;
  final List<Join> joins;
  final int? limit, offset;
  final List<String> groupBys;

  ReadQuery._(
    Query<T> query, {
    this.whereClause,
    this.orderByProps,
    this.fieldSelections = const {},
    this.joins = const [],
    this.groupBys = const [],
    this.limit,
    this.offset,
  }) : super(query);

  @override
  Query<T> get $query => (super.$query) as Query<T>;

  @override
  String get statement => runner.serializer.acceptReadQuery(this);

  @override
  Future<List<Map<String, dynamic>>> execute() => runner.query(this);

  @override
  Future<num> average(String field) {
    return AverageAggregate(this, field).get();
  }

  @override
  Future<int> count({String? field, bool distinct = false}) {
    return CountAggregate(this, field, distinct).get();
  }

  @override
  Future<String> groupConcat(String field, String separator) {
    return GroupConcatAggregate(this, field, separator).get();
  }

  @override
  Future<num> max(String field) => MaxAggregate(this, field).get();

  @override
  Future<num> min(String field) => MinAggregate(this, field).get();

  @override
  Future<num> sum(String field) {
    return SumAggregate(this, field).get();
  }

  Future<List<T>> findMany({int? limit, int? offset, List<OrderBy<T>>? orderBy}) => $query.findMany(
        limit: limit,
        offset: offset,
        where: (_) => whereClause!,
        orderBy: orderBy,
      );

  Future<bool> exists() async {
    final existsQuery = ReadQuery._(
      $query,
      fieldSelections: {$query.entity.primaryKey.columnName},
      whereClause: whereClause,
      limit: 1,
    );
    final result = await $query.runner.query(existsQuery);
    return result.isNotEmpty;
  }

  Future<T?> findOne() => $query.findOne(where: (_) => whereClause!);

  Future<void> delete() => DeleteQuery(
        $query,
        whereClause: whereClause!,
      ).execute();

  @override
  ReadQuery<T> withRelations(
    List<Join<T, Entity, EntityRelation<T, Entity>>> Function(JoinBuilder<T> builder) builder,
  ) {
    joins
      ..clear()
      ..addAll(builder.call(_JoinBuilderImpl<T>()));
    return this;
  }

  Future<void> update(UpdateEntity<T> update) => $query
      .update(
        where: (_) => whereClause!,
        update: update,
      )
      .execute();
}

final class _JoinBuilderImpl<T extends Entity<T>> extends JoinBuilder<T> {}

final class InsertQuery extends QueryBase<InsertQuery> {
  final Map<String, dynamic> data;
  final String primaryKey;

  InsertQuery(
    super._query, {
    required this.data,
    required this.primaryKey,
  });

  @override
  Future<dynamic> execute() => runner.insert(this);

  @override
  String get statement => runner.serializer.acceptInsertQuery(this);
}

final class InsertManyQuery extends QueryBase<InsertManyQuery> {
  final String primaryKey;
  final List<Map<String, dynamic>> values;

  InsertManyQuery(
    super.tableName, {
    required this.values,
    required this.primaryKey,
  });

  @override
  String get statement => runner.serializer.acceptInsertManyQuery(this);

  @override
  Future<dynamic> execute() => runner.insertMany(this);
}

@protected
final class DeleteQuery extends QueryBase<DeleteQuery> {
  final WhereClause whereClause;

  DeleteQuery(super._query, {required this.whereClause});

  @override
  String get statement => runner.serializer.acceptDeleteQuery(this);

  @override
  Future<void> execute() => runner.delete(this);
}
