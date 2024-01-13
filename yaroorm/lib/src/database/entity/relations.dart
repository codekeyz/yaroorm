part of 'entity.dart';

abstract class EntityRelation<RelatedModel extends Entity> {
  final Entity owner;

  EntityRelation(this.owner);

  DriverContract get _driver => owner._driver;

  Query<RelatedModel> get _query => Query.table<RelatedModel>().driver(_driver);

  get();

  delete();
}

class HasOne<RelatedModel extends Entity> extends EntityRelation<RelatedModel> {
  final String foreignKey;

  HasOne(this.foreignKey, super._owner);

  Future<RelatedModel> set(RelatedModel model) async {
    model.withDriver(_driver);

    final data = model.to_db_data..[foreignKey] = owner.id!;
    data[model.entityMeta.primaryKey] = await _query.insert(data);
    return serializedPropsToEntity<RelatedModel>(
      data,
      converters: _driver.typeconverters,
    ).withDriver(_driver) as RelatedModel;
  }

  @override
  Future<RelatedModel?> get() => _query.whereEqual(foreignKey, owner.id!).findOne();

  @override
  Future<void> delete() => _query.whereEqual(foreignKey, owner.id!).delete();
}

class HasMany<RelatedModel extends Entity> extends EntityRelation<RelatedModel> {
  final String foreignKey;

  HasMany(this.foreignKey, super.owner);

  @override
  Future<List<RelatedModel>> get() => _query.whereEqual(foreignKey, owner.id!).findMany();

  Future<RelatedModel?> first() => _query.whereEqual(foreignKey, owner.id!).findOne();

  Map<String, dynamic> _serializeModel(RelatedModel model) {
    model.withDriver(_driver);
    return model.to_db_data..[foreignKey] = owner.id!;
  }

  Future<void> add(RelatedModel model) => _query.insert(_serializeModel(model));

  Future<void> addAll(Iterable<RelatedModel> model) => _query.insertMany(model.map(_serializeModel).toList());

  @override
  Future<void> delete() => _query.whereEqual(foreignKey, owner.id!).delete();
}
