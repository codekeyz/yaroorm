part of 'entity.dart';

abstract class EntityTypeConverter<DartType, DBType> {
  const EntityTypeConverter();

  Type get _dartType => DartType;

  DBType? toDbType(DartType? value);

  DartType? fromDbType(DBType? value);
}

Map<Type, EntityTypeConverter> combineConverters(
  List<EntityTypeConverter> custom,
  List<EntityTypeConverter> driverProvided,
) {
  return {
    for (final converter in [...custom, ...driverProvided]) converter._dartType: converter,
  };
}

Map<String, dynamic> entityToDbData<Model extends Entity<Model>>(Model entity) {
  final typeInfo = Query.getEntity<Model>(type: entity.runtimeType);
  final typeConverters = combineConverters(typeInfo.converters, entity._driver.typeconverters);

  Object? getValue(DBEntityField field) {
    final value = typeInfo.mirror(entity, field.dartName);
    final typeConverter = typeConverters[field.type];
    return typeConverter == null ? value : typeConverter.toDbType(value);
  }

  return {
    for (final entry in typeInfo.editableColumns) entry.columnName: getValue(entry),
  };
}

@internal
Map<String, dynamic> entityMapToDbData<T extends Entity<T>>(
  Map<Symbol, dynamic> values,
  Map<Type, EntityTypeConverter> typeConverters, {
  bool onlyPropertiesPassed = false,
}) {
  final entity = Query.getEntity<T>();
  final editableFields = entity.fieldsRequiredForCreate;

  final resultsMap = <String, dynamic>{};

  final fieldsToWorkWith = !onlyPropertiesPassed
      ? editableFields
      : values.keys.map((key) => editableFields.firstWhere((field) => field.dartName == key));

  for (final field in fieldsToWorkWith) {
    var value = values[field.dartName];

    final typeConverter = typeConverters[field.type];
    value = typeConverter == null ? value : typeConverter.toDbType(value);
    if (!field.nullable && value == null) {
      throw Exception('Null Value not allowed for Field ${field.dartName} on $T Entity');
    }

    resultsMap[field.columnName] = value;
  }

  return resultsMap;
}

@internal
Model dbDataToEntity<Model extends Entity<Model>>(
  Map<String, dynamic> dataFromDb,
  EntityTypeDefinition<Model> entity,
  Map<Type, EntityTypeConverter> converters,
) {
  final resultsMap = <Symbol, dynamic>{};
  for (final entry in entity.columns) {
    final value = dataFromDb[entry.columnName];
    final typeConverter = converters[entry.type];
    resultsMap[entry.dartName] = typeConverter == null ? value : typeConverter.fromDbType(value);
  }

  return entity.build(resultsMap);
}
