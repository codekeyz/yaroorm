part of 'entity.dart';

abstract class EntityTypeConverter<DartType, DBType> {
  const EntityTypeConverter();

  Type get _dartType => DartType;

  DBType? toDbType(DartType? value);

  DartType? fromDbType(DBType? value);
}

class _DateTimeConverter extends EntityTypeConverter<DateTime, String> {
  const _DateTimeConverter();

  String padValue(value) => value.toString().padLeft(2, '0');

  @override
  DateTime? fromDbType(String? dbType) => dbType == null ? null : DateTime.parse(dbType);

  @override
  String? toDbType(DateTime? date) {
    date = date?.toUtc();
    return date == null
        ? null
        : '${date.year}-${padValue(date.month)}-${padValue(date.day)} ${padValue(date.hour)}:${padValue(date.minute)}:${padValue(date.second)}';
  }
}

class BooleanConverter extends EntityTypeConverter<bool, int> {
  const BooleanConverter();

  @override
  bool? fromDbType(int? value) => value == null ? null : value != 0;

  @override
  int? toDbType(bool? value) => (value == null || value == false) ? 0 : 1;
}

const dateTimeConverter = _DateTimeConverter();
const booleanConverter = BooleanConverter();

List<EntityTypeConverter> _combineConverters(
  List<EntityTypeConverter> custom,
  List<EntityTypeConverter> driverProvided,
) {
  final converters = <EntityTypeConverter>[...custom];
  for (final converter in driverProvided) {
    if (!converters.any((e) => e._dartType == converter._dartType)) converters.add(converter);
  }
  return converters;
}

Map<String, dynamic> _entityToRecord<T extends Entity>(T instance, {List<EntityTypeConverter> converters = const []}) {
  final entityMeta = getEntityMetaData(instance.runtimeType);

  final entityProperties = getEntityProperties(instance.runtimeType);
  final mappedConverters = _combineConverters(entityMeta.converters ?? [], converters).fold(
    <Type, EntityTypeConverter>{},
    (preV, e) => preV..[e._dartType] = e,
  );

  final instanceMirror = entity.reflect(instance);
  final serializedEntityMap = <String, dynamic>{};
  for (final entry in entityProperties.entries) {
    final value = instanceMirror.invokeGetter(entry.key);
    final typeConverter = mappedConverters[entry.value.type];
    serializedEntityMap[entry.value.dbColumnName] = typeConverter == null ? value : typeConverter.toDbType(value);
  }

  if (serializedEntityMap[entityMeta.primaryKey] == null) serializedEntityMap.remove(entityMeta.primaryKey);
  if (!entityMeta.timestamps) {
    serializedEntityMap
      ..remove(entityMeta.createdAtColumn)
      ..remove(entityMeta.updatedAtColumn);
  }

  return serializedEntityMap;
}

Entity recordToEntity<Model>(final Map<String, dynamic> json, {List<EntityTypeConverter> converters = const []}) {
  final mirror = reflectEntity<Model>();
  final entityMeta = getEntityMetaData(Model);
  final entityProperties = getEntityProperties(Model);
  final constructorMethod =
      mirror.declarations.entries.firstWhereOrNull((e) => e.key == '$Model')?.value as MethodMirror;
  final constructorParams = constructorMethod.parameters;

  final mappedConverters = _combineConverters(entityMeta.converters ?? [], converters).fold(
    <Type, EntityTypeConverter>{},
    (preV, e) => preV..[e._dartType] = e,
  );

  final transformedRecordMap = <String, dynamic>{};
  for (final entry in entityProperties.entries) {
    final value = json[entry.value.dbColumnName];
    final typeConverter = mappedConverters[entry.value.type];
    transformedRecordMap[entry.value.dartName] = typeConverter == null ? value : typeConverter.fromDbType(value);
  }

  final namedDeps = constructorParams
      .where((e) => e.isNamed)
      .map((e) => (name: e.simpleName, value: transformedRecordMap[e.simpleName]))
      .fold<Map<Symbol, dynamic>>({}, (prev, e) => prev..[Symbol(e.name)] = e.value);

  final dependencies =
      constructorParams.where((e) => !e.isNamed).map((e) => transformedRecordMap[e.simpleName]).toList();

  final newEntityInstance = mirror.newInstance('', dependencies, namedDeps);
  return (newEntityInstance as Entity)
    ..id = json['id']
    ..createdAt = transformedRecordMap['createdAt']
    ..updatedAt = transformedRecordMap['updatedAt'];
}
