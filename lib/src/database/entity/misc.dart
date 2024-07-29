import 'dart:convert';

import 'entity.dart';

const dateTimeConverter = DateTimeConverter();
const booleanConverter = BooleanConverter();

const intListConverter = _ListOfObject<int>();
const stringListConverter = _ListOfObject<String>();
const numListConverter = _ListOfObject<num>();
const doubleListConverter = _ListOfObject<double>();

const defaultListConverters = [
  intListConverter,
  numListConverter,
  doubleListConverter,
  stringListConverter,
];

class DateTimeConverter extends EntityTypeConverter<DateTime, String> {
  const DateTimeConverter();

  String padValue(v) => v.toString().padLeft(2, '0');

  @override
  DateTime? fromDbType(String? value) =>
      value == null ? null : DateTime.parse(value);

  @override
  String? toDbType(DateTime? value) {
    if (value == null) return null;
    return '${value.year}-${padValue(value.month)}-${padValue(value.day)} ${padValue(value.hour)}:${padValue(value.minute)}:${padValue(value.second)}';
  }
}

class BooleanConverter extends EntityTypeConverter<bool, int> {
  const BooleanConverter();

  @override
  bool? fromDbType(int? value) => value == null ? null : value != 0;

  @override
  int? toDbType(bool? value) => (value == null || value == false) ? 0 : 1;
}

class _ListOfObject<T extends Object>
    extends EntityTypeConverter<List<T>, String> {
  const _ListOfObject();
  @override
  List<T> fromDbType(covariant String value) => List<T>.from(jsonDecode(value));

  @override
  String toDbType(covariant List<T> value) => jsonEncode(value);
}
