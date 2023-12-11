import 'dart:convert';

import 'package:dotenv/dotenv.dart';

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

typedef YarooAppConfig = Map<String, dynamic>;

extension ConfigExt on YarooAppConfig {
  static final String name = 'name';
  static final String url = 'url';
  static final String port = 'port';

  String get appName => this[ConfigExt.name];

  Uri get appUri {
    final url = this[ConfigExt.url];
    return Uri.tryParse(url) ??
        (throw ArgumentError.value(url, null, 'APP_URL is not a valid url'));
  }

  String get appUrl => this[ConfigExt.url];

  String get appPort => this[ConfigExt.port] ?? appUri.port;
}
