part of 'entity.dart';

abstract class EntityTypeConverter<DartType, DBType> {
  const EntityTypeConverter();

  Type get _dartType => DartType;

  DBType? toDbType(DartType? value);

  DartType? fromDbType(DBType? value);
}

class DateTimeConverter extends EntityTypeConverter<DateTime, String> {
  const DateTimeConverter();

  String padValue(v) => v.toString().padLeft(2, '0');

  @override
  DateTime? fromDbType(String? value) {
    return value == null ? null : DateTime.parse(value);
  }

  @override
  String? toDbType(DateTime? value) {
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

Map<Type, EntityTypeConverter> combineConverters(
  List<EntityTypeConverter> custom,
  List<EntityTypeConverter> driverProvided,
) {
  return {
    for (final converter in [...custom, ...driverProvided]) converter._dartType: converter,
  };
}

UnmodifiableMapView<String, dynamic> entityToDbData<Model extends Entity<Model>>(Model value) {
  final entity = Query.getEntity<Model>(type: value.runtimeType);
  final typeConverters = combineConverters(entity.converters, value._driver.typeconverters);
  final mirror = entity.mirror(value);

  Object? getValue(DBEntityField field) {
    final value = mirror.get(field.dartName);
    final typeConverter = typeConverters[field.type];
    return typeConverter == null ? value : typeConverter.toDbType(value);
  }

  final data = {
    for (final entry in entity.editableColumns) entry.columnName: getValue(entry),
  };

  return UnmodifiableMapView(data);
}

@internal
UnmodifiableMapView<String, dynamic> entityMapToDbData<T extends Entity<T>>(
  Map<Symbol, dynamic> values,
  Map<Type, EntityTypeConverter> typeConverters, {
  bool onlyPropertiesPassed = false,
}) {
  final entity = Query.getEntity<T>();
  final editableFields = entity.editableColumns;

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

  return UnmodifiableMapView(resultsMap);
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
