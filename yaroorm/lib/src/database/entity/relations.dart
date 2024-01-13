part of 'entity.dart';

abstract class EntityRelation<RelatedModel extends Entity> {
  final Entity owner;

  EntityRelation(this.owner);

  DriverContract get _driver => owner._driver;

  Query<RelatedModel> get _query => Query.table<RelatedModel>().driver(_driver);

  get();
}

class HasOne<RelatedModel extends Entity> extends EntityRelation<RelatedModel> {
  final String foreignKey;

  HasOne(this.foreignKey, super._owner);

  Future<RelatedModel> set(RelatedModel model) async {
    model.withDriver(_driver);

    final data = model.to_db_data..[foreignKey] = owner.id!;
    data[model.entityMeta.primaryKey] = await _query.insert(data);
    return serializedPropsToEntity<RelatedModel>(data, converters: _driver.typeconverters) as RelatedModel;
  }

  @override
  Future<RelatedModel?> get() => _query.whereEqual(foreignKey, owner.id!).findOne();
}

class HasMany<RelatedModel extends Entity> extends EntityRelation<RelatedModel> {
  final String foreignKey;

  HasMany(this.foreignKey, super.owner);

  @override
  Future<List<RelatedModel>> get() => _query.whereEqual(foreignKey, owner.id!).findMany();

  insert(RelatedModel model) {
    final data = model.to_db_data;
    data[foreignKey] = owner.id!;
  }
}
