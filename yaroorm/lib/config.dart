import 'dart:convert';

import 'package:dotenv/dotenv.dart';

import 'src/database/driver/driver.dart';
import 'migration.dart';

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
  T getValue<T>(String name, {T? defaultValue, bool allowEmpty = false}) {
    final value = this[name] ?? defaultValue;
    if (value is! T) {
      throw ArgumentError.value(value, null, 'Invalid value provided for $name');
    }
    if (value != null && value.toString().trim().isEmpty && !allowEmpty) {
      throw ArgumentError.value(value, null, 'Empty value not allowed for $name');
    }
    return value;
  }
}

class DatabaseConfig {
  final String defaultConnName;
  final List<DatabaseConnection> connections;

  final String migrationsTable;
  final List<Migration> migrations;

  DatabaseConnection get defaultDBConn => connections.firstWhere((e) => e.name == defaultConnName);

  const DatabaseConfig._(
    this.defaultConnName, {
    required this.connections,
    required this.migrationsTable,
    this.migrations = const [],
  });

  factory DatabaseConfig.from(Map<String, dynamic> config) {
    final defaultConnName = config.getValue<String?>('default');
    if (defaultConnName == null) {
      throw ArgumentError('Default database connection not provided');
    }

    final connInfos = config.getValue<Map<String, dynamic>>('connections', defaultValue: {});
    if (connInfos.isEmpty) {
      throw ArgumentError('Database connection infos not provided');
    }

    final connections = connInfos.entries.map((e) => DatabaseConnection.from(e.key, e.value));
    final hasDefault = connections.any((e) => e.name == defaultConnName);
    if (!hasDefault) throw ArgumentError('Database connection info not found for $defaultConnName');

    return DatabaseConfig._(
      defaultConnName,
      connections: connections.toList(),
      migrationsTable: config.getValue('migrations_table', defaultValue: 'migrations'),
      migrations: config.getValue('migrations', defaultValue: const []),
    );
  }
}
