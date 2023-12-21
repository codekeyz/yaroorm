import 'dart:convert';

import 'package:dotenv/dotenv.dart';

export 'app.dart';
export 'database.dart';

typedef ConfigResolver<T extends Map<String, dynamic>> = T Function();

DotEnv? _env;

T? env<T>(String name, [T? defaultValue]) {
  _env ??= DotEnv(quiet: true, includePlatformEnvironment: false)..load();
  final strVal = _env![name];

  if (strVal == null) return defaultValue;
  final parsedVal = switch (T) {
    const (String) => strVal,
    const (int) => int.tryParse(strVal),
    const (num) => num.tryParse(strVal),
    const (double) => double.tryParse(strVal),
    const (List<String>) => jsonDecode(strVal),
    _ => throw ArgumentError.value(T, null, 'Unsupported Type used in `env` call.'),
  };
  return (parsedVal ?? defaultValue) as T;
}

extension ConfigExtension on Map<String, dynamic> {
  T getValue<T>(String name, {T? defaultValue}) {
    final value = this[name] ?? defaultValue;
    if (value is! T) {
      throw ArgumentError.value(value, null, 'Invalid value provided for config type $T');
    }
    return value;
  }
}
