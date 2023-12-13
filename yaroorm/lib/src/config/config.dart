extension ConfigExtension on Map<String, dynamic> {
  T? getValue<T>(String name) {
    final value = this[name];
    if (value == null) return null;
    if (value is! T) {
      throw ArgumentError.value(value, null, 'Invalid value provided for config type $T');
    }
    return value;
  }
}
