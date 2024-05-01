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

  get({bool refresh = false});

  delete();
}

final class HasOne<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel> {
  final String foreignKey;

  HasOne._(this.foreignKey, super._owner);

  ReadQuery<RelatedModel> get $readQuery => _query.where((q) => q.$equal(foreignKey, parentId));

  @override
  Future<RelatedModel?> get({bool refresh = false}) => $readQuery.findOne();

  @override
  Future<void> delete() => $readQuery.delete();

  Future<void> exists() => $readQuery.exists();
}

final class HasMany<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel> {
  final Map<String, dynamic> _cache;
  final String foreignKey;

  HasMany._(this.foreignKey, super.parent, this._cache);

  ReadQuery<RelatedModel> get $readQuery => _query.where((q) => q.$equal(foreignKey, parentId));

  @override
  Future<List<RelatedModel>> get({
    int? limit,
    int? offset,
    List<OrderBy<RelatedModel>>? orderBy,
    bool refresh = false,
  }) {
    return $readQuery.findMany(
      limit: limit,
      offset: offset,
      orderBy: orderBy,
    );
  }

  Future<RelatedModel?> get first => $readQuery.findOne();

  @override
  Future<void> delete() => $readQuery.delete();
}

final class BelongsTo<Parent extends Entity<Parent>, RelatedModel extends Entity<RelatedModel>>
    extends EntityRelation<Parent, RelatedModel> {
  final Map<String, dynamic> _cache;
  final String foreignKey;
  final dynamic value;

  BelongsTo._(this.foreignKey, super.parent, this.value, this._cache);

  ReadQuery<RelatedModel> get _readQuery {
    return Query.table<RelatedModel>().driver(_driver).where((q) => q.$equal(foreignKey, value));
  }

  @override
  Future<RelatedModel?> get({bool refresh = false}) async {
    if (_cache.isNotEmpty && !refresh) {
      final typeData = Query.getEntity<RelatedModel>();
      return serializedPropsToEntity<RelatedModel>(
        _cache,
        typeData,
        combineConverters(typeData.converters, _driver.typeconverters),
      );
    }
    return _readQuery.findOne();
  }

  @override
  Future<void> delete() => _readQuery.delete();
}
