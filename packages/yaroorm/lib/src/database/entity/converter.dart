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
  DateTime? fromDbType(String? value) {
    return value == null ? null : DateTime.parse(value);
  }

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

Map<String, dynamic> _serializeEntityProps<Model extends Entity>(
  Model instance, {
  List<EntityTypeConverter> converters = const [],
}) {
  final entity = Query.getEntity<Model>();

  final instanceMirror = entity.mirror(instance);
  final allConverters = _combineConverters(entity.converters, converters);

  /// database value conversion back to Dart Types
  toDartValue(DBEntityField field) {
    final value = instanceMirror.get(field.dartName);
    final typeConverter = allConverters[field.type];
    return typeConverter == null ? value : typeConverter.toDbType(value);
  }

  return {
    for (final entry in entity.columns) entry.columnName: toDartValue(entry),
  };
}

Entity serializedPropsToEntity<Model extends Entity>(
  final Map<String, dynamic> json, {
  List<EntityTypeConverter> converters = const [],
}) {
  final entity = Query.getEntity<Model>();
  final allConverters = _combineConverters(entity.converters, converters);

  final resultsMap = <Symbol, dynamic>{};
  for (final entry in entity.columns) {
    final value = json[entry.columnName];
    final typeConverter = allConverters[entry.type];
    resultsMap[entry.dartName] =
        typeConverter == null ? value : typeConverter.fromDbType(value);
  }

  return entity.build(resultsMap);
}
