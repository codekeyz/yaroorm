import 'package:yaroo/src/config/config.dart';
import 'package:yaroorm/yaroorm.dart';

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
