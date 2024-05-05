part of 'entity.dart';

abstract class EntityRelation<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>> {
  final Parent parent;

  late final Query<RelatedModel> _query;

  EntityRelation(this.parent) : _query = Query.table<RelatedModel>().driver(parent._driver);

  Object get parentId {
    final typeInfo = parent.typeData;
    return typeInfo.mirror.call(parent).get(typeInfo.primaryKey.dartName)!;
  }

  DriverContract get _driver => parent._driver;

  /// This holds preloaded values from `withRelation`
  dynamic get value =>
      throw StateError('No preloaded data for this relation. Did you forget to call `withRelations` ?');

  get({bool refresh = false});

  delete();
}

final class HasOne<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel> {
  final String relatedModelPrimaryKey;
  final dynamic relatedModelValue;

  HasOne._(
    this.relatedModelPrimaryKey,
    this.relatedModelValue,
    super._owner,
  );

  ReadQuery<RelatedModel> get $readQuery => _query.where((q) => q.$equal(relatedModelPrimaryKey, relatedModelValue));

  @override
  FutureOr<RelatedModel?> get({bool refresh = false}) => $readQuery.findOne();

  @override
  Future<void> delete() => $readQuery.delete();

  Future<void> exists() => $readQuery.exists();
}

final class HasMany<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel> {
  final List<Map<String, dynamic>>? _cache;
  final String foreignKey;

  HasMany._(this.foreignKey, super.parent, this._cache);

  ReadQuery<RelatedModel> get $readQuery => _query.where((q) => q.$equal(foreignKey, parentId));

  @override
  List<RelatedModel> get value {
    if (_cache == null) {
      return super.value;
    } else if (_cache!.isEmpty) {
      return <RelatedModel>[];
    }

    final typeData = Query.getEntity<RelatedModel>();
    return _cache!
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
      return value;
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
}

final class BelongsTo<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel> {
  final Map<String, dynamic>? _cache;
  final String foreignKey;
  final dynamic foreignKeyValue;

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
    } else if (_cache!.isEmpty) {
      return null;
    }
    final typeData = Query.getEntity<RelatedModel>();
    return dbDataToEntity<RelatedModel>(
      _cache!,
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
