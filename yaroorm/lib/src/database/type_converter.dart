part of 'entity.dart';

abstract class EntityTypeConverter<DartType, DBType> {
  const EntityTypeConverter();

  Type get _dartType => DartType;

  Type get _dbType => DBType;

  DBType? toDbType(DartType? dartType);

  DartType? fromDbType(DBType? dbType);
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

class _BooleanConverter extends EntityTypeConverter<bool, int> {
  const _BooleanConverter();

  @override
  bool? fromDbType(int? dbType) => dbType == null ? null : dbType != 0;

  @override
  int? toDbType(bool? value) => (value == null || value == false) ? 0 : 1;
}

const _dateTimeConverter = _DateTimeConverter();
const _booleanConverter = _BooleanConverter();
