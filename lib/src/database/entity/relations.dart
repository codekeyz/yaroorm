part of 'entity.dart';

sealed class EntityRelation<Parent extends Entity<Parent>,
    RelatedModel extends Entity<RelatedModel>, Result extends Object> {
  final Parent parent;
  final Query<RelatedModel> _query;

  EntityRelation(this.parent)
      : _query = Query.table<RelatedModel>().driver(parent._driver);

  Object get parentId {
    final typeInfo = parent._typeDef;
    return typeInfo.mirror.call(parent, typeInfo.primaryKey.dartName)!;
  }

  DriverContract get _driver => parent._driver;

  /// This holds preloaded values from `withRelation`
  Result? get value => throw StateError(
      'No preloaded data for this relation. Did you forget to call `withRelations` ?');

  get({bool refresh = false});

  bool get loaded;

  delete();
}

final class HasOne<Parent extends Entity<Parent>,
        RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel, RelatedModel> {
  final String _relatedModelPrimaryKey;
  final dynamic _relatedModelValue;
  final Map<String, dynamic>? _cache;

  HasOne._(
    this._relatedModelPrimaryKey,
    this._relatedModelValue,
    super._owner,
    this._cache,
  );

  @override
  bool get loaded => _cache != null;

  @override
  RelatedModel? get value {
    if (_cache == null) {
      return super.value;
    } else if (_cache.isEmpty) {
      return null;
    }
    final typeData = Query.getEntity<RelatedModel>();
    return dbDataToEntity<RelatedModel>(
      _cache,
      typeData,
      combineConverters(typeData.converters, _driver.typeconverters),
    );
  }

  @internal
  ReadQuery<RelatedModel> get $readQuery => _query
      .where((q) => q.$equal(_relatedModelPrimaryKey, _relatedModelValue));

  @override
  FutureOr<RelatedModel?> get({bool refresh = false}) async {
    if (_cache != null && !refresh) return value;
    return $readQuery.findOne();
  }

  @override
  Future<void> delete() => $readQuery.delete();

  Future<void> exists() => $readQuery.exists();
}

final class HasMany<Parent extends Entity<Parent>,
        RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel, List<RelatedModel>> {
  final List<Map<String, dynamic>>? _cache;
  final String foreignKey;

  HasMany._(this.foreignKey, super.parent, this._cache);

  ReadQuery<RelatedModel> get $readQuery =>
      _query.where((q) => q.$equal(foreignKey, parentId));

  @override
  bool get loaded => _cache != null;

  @override
  List<RelatedModel>? get value {
    if (_cache == null) {
      return super.value;
    } else if (_cache.isEmpty) {
      return <RelatedModel>[];
    }

    final typeData = Query.getEntity<RelatedModel>();
    return _cache
        .map((data) => dbDataToEntity<RelatedModel>(
              data,
              typeData,
              combineConverters(typeData.converters, _driver.typeconverters),
            ))
        .toList();
  }

  @override
  FutureOr<List<RelatedModel>> get({
    int? limit,
    int? offset,
    List<OrderBy<RelatedModel>>? orderBy,
    bool refresh = false,
  }) async {
    if (_cache != null && !refresh) {
      return value!;
    }

    return $readQuery.findMany(
      limit: limit,
      offset: offset,
      orderBy: orderBy,
    );
  }

  FutureOr<RelatedModel?> get first => $readQuery.findOne();

  @override
  Future<void> delete() => $readQuery.delete();

  Future<RelatedModel> insert(
      CreateRelatedEntity<Parent, RelatedModel> related) async {
    final data = _CreateEntity<RelatedModel>(
        {...related.toMap, related.field: parentId});
    return $readQuery.$query.insert(data);
  }

  Future<void> insertMany(
      List<CreateRelatedEntity<Parent, RelatedModel>> related) async {
    final data = related
        .map(
            (e) => _CreateEntity<RelatedModel>({...e.toMap, e.field: parentId}))
        .toList();
    return $readQuery.$query.insertMany(data);
  }
}

class _CreateEntity<T extends Entity<T>> extends CreateEntity<T> {
  final Map<Symbol, dynamic> _data;
  const _CreateEntity(this._data);
  @override
  Map<Symbol, dynamic> get toMap => _data;
}

final class BelongsTo<Parent extends Entity<Parent>,
        RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel, RelatedModel> {
  final Map<String, dynamic>? _cache;
  final String foreignKey;
  final dynamic foreignKeyValue;

  @override
  bool get loaded => _cache != null;

  BelongsTo._(
    this.foreignKey,
    this.foreignKeyValue,
    super.parent,
    this._cache,
  );

  ReadQuery<RelatedModel> get _readQuery {
    return Query.table<RelatedModel>().driver(_driver).where((q) => q.$equal(
          foreignKey,
          foreignKeyValue,
        ));
  }

  @override
  RelatedModel? get value {
    if (_cache == null) {
      return super.value;
    } else if (_cache.isEmpty) {
      return null;
    }
    final typeData = Query.getEntity<RelatedModel>();
    return dbDataToEntity<RelatedModel>(
      _cache,
      typeData,
      combineConverters(typeData.converters, _driver.typeconverters),
    );
  }

  @override
  FutureOr<RelatedModel?> get({bool refresh = false}) async {
    if (_cache != null && !refresh) {
      return value;
    }
    return _readQuery.findOne();
  }

  @override
  Future<void> delete() => _readQuery.delete();
}
