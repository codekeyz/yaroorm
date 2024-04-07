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
    for (final converter in [...custom, ...driverProvided])
      converter._dartType: converter,
  };
}

Map<String, dynamic> conformToDbTypes<Model extends Entity>(
  Map<Symbol, dynamic> data,
  Map<Type, EntityTypeConverter> converters,
) {
  final entity = Query.getEntity<Model>();

  Object? toDbType(DBEntityField field) {
    final value = data[field.dartName];
    final typeConverter = converters[field.type];
    return typeConverter == null ? value : typeConverter.toDbType(value);
  }

  return {
    for (final entry in entity.editableColumns)
      entry.columnName: toDbType(entry),
  };
}

Model serializedPropsToEntity<Model extends Entity>(
  Map<String, dynamic> dataFromDb,
  DBEntity<Model> entity,
  Map<Type, EntityTypeConverter> converters,
) {
  final resultsMap = <Symbol, dynamic>{};
  for (final entry in entity.columns) {
    final value = dataFromDb[entry.columnName];
    final typeConverter = converters[entry.type];
    resultsMap[entry.dartName] =
        typeConverter == null ? value : typeConverter.fromDbType(value);
  }

  return entity.build(resultsMap);
}
