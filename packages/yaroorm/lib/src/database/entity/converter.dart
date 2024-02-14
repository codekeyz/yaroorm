part of 'entity.dart';

abstract class EntityTypeConverter<DartType, DBType> {
  const EntityTypeConverter();

  Type get _dartType => DartType;

  DBType? toDbType(DartType? value);

  DartType? fromDbType(DBType? value);
}

class DateTimeConverter extends EntityTypeConverter<DateTime, String> {
  const DateTimeConverter();

  String padValue(value) => value.toString().padLeft(2, '0');

  @override
  DateTime? fromDbType(String? value) =>
      value == null ? null : DateTime.parse(value);

  @override
  String? toDbType(DateTime? value) {
    value = value?.toUtc();
    return value == null
        ? null
        : '${value.year}-${padValue(value.month)}-${padValue(value.day)} ${padValue(value.hour)}:${padValue(value.minute)}:${padValue(value.second)}';
  }
}

class BooleanConverter extends EntityTypeConverter<bool, int> {
  const BooleanConverter();

  @override
  bool? fromDbType(int? value) => value == null ? null : value != 0;

  @override
  int? toDbType(bool? value) => (value == null || value == false) ? 0 : 1;
}

const dateTimeConverter = DateTimeConverter();
const booleanConverter = BooleanConverter();

Map<Type, EntityTypeConverter> _combineConverters(
  List<EntityTypeConverter> custom,
  List<EntityTypeConverter> driverProvided,
) {
  return {
    for (final converter in [...custom, ...driverProvided])
      converter._dartType: converter,
  };
}

Map<String, dynamic> _serializeEntityProps<T extends Entity>(
  T instance, {
  List<EntityTypeConverter> converters = const [],
}) {
  final entityMeta = getEntityMetaData(instance.runtimeType);
  final entityProperties = getEntityProperties(instance.runtimeType);
  if (instance.id != null) {
    entityProperties['id'] = EntityPropertyData(
        'id', entityMeta.primaryKey, instance.id.runtimeType);
  }

  final instanceMirror = entity.reflect(instance);
  final mappedConverters =
      _combineConverters(entityMeta.converters ?? [], converters);

  /// database value conversion back to Dart Types
  toDartValue(MapEntry<String, EntityPropertyData> entry) {
    final value = instanceMirror.invokeGetter(entry.key);
    final typeConverter = mappedConverters[entry.value.type];
    return typeConverter == null ? value : typeConverter.toDbType(value);
  }

  return {
    for (final entry in entityProperties.entries)
      entry.value.dbColumnName: toDartValue(entry),
  };
}

Entity serializedPropsToEntity<Model>(
  final Map<String, dynamic> json, {
  List<EntityTypeConverter> converters = const [],
}) {
  final mirror = reflectEntity<Model>();
  final entityMeta = getEntityMetaData(Model);
  final entityProperties = getEntityProperties(Model);
  final constructorMethod = mirror.declarations.entries
      .firstWhereOrNull((e) => e.key == '$Model')
      ?.value as MethodMirror;
  final constructorParams = constructorMethod.parameters;

  final mappedConverters =
      _combineConverters(entityMeta.converters ?? [], converters);

  /// conversion to Database compatible types using [EntityTypeConverter]
  final transformedRecordMap = <String, dynamic>{};
  for (final entry in entityProperties.entries) {
    final value = json[entry.value.dbColumnName];
    final typeConverter = mappedConverters[entry.value.type];
    transformedRecordMap[entry.value.dartName] =
        typeConverter == null ? value : typeConverter.fromDbType(value);
  }

  final namedDeps = constructorParams
      .where((e) => e.isNamed)
      .map((e) =>
          (name: e.simpleName, value: transformedRecordMap[e.simpleName]))
      .fold<Map<Symbol, dynamic>>(
          {}, (prev, e) => prev..[Symbol(e.name)] = e.value);

  final dependencies = constructorParams
      .where((e) => !e.isNamed)
      .map((e) => transformedRecordMap[e.simpleName])
      .toList();

  final newEntityInstance = mirror.newInstance('', dependencies, namedDeps);
  return (newEntityInstance as Entity)
    ..id = json['id']
    ..createdAt = transformedRecordMap['createdAt']
    ..updatedAt = transformedRecordMap['updatedAt']
    .._isLoadedFromDB = true;
}
