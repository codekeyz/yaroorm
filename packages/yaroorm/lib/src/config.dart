import 'database/driver/driver.dart';
import 'migration.dart';

class YaroormConfig {
  final String defaultConnName;
  final List<DatabaseConnection> connections;

  final String migrationsTable;
  final List<Migration> migrations;

  DatabaseConnection get defaultDBConn =>
      connections.firstWhere((e) => e.name == defaultConnName);

  YaroormConfig(
    this.defaultConnName, {
    required this.connections,
    this.migrationsTable = 'migrations',
    this.migrations = const [],
  }) {
    final hasDefault = connections.any((e) => e.name == defaultConnName);
    if (!hasDefault) {
      throw ArgumentError(
          'Database connection info not found for $defaultConnName');
    }
  }
}
