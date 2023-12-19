import 'package:postgres/postgres.dart' as pg;

import 'sqlite_driver.dart' show SqliteSerializer;

import '../../access/access.dart';
import '../../access/primitives/serializer.dart';
import '../database.dart';

class PostgreSqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  late pg.Connection? db;

  PostgreSqlDriver(this.config);

  static const _serializer = PgSqlPrimitiveSerializer();

  @override
  Future<DatabaseDriver> connect() async {
    db = await pg.Connection.open(pg.Endpoint(
      host: config.host!,
      database: config.database,
      username: config.username,
      password: config.password,
      port: config.port == null ? 5432 : int.parse(config.port!),
    ));
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect() async {
    await db?.close();
  }

  Future<List<Map<String, dynamic>>> _execRawQuery(String script) async {
    final result = await db?.execute(script);
    if (result == null) return [];
    return result.map((e) => e.toColumnMap()).toList();
  }

  @override
  Future execute(String script) async {
    final result = await db?.execute(script);
    return result?.map((e) => e.toColumnMap()).toList();
  }

  @override
  Future insert(String tableName, Map<String, dynamic> data) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  bool get isOpen => db != null && db!.isOpen;

  @override
  Future<List<Map<String, dynamic>>> query(Query query) async {
    final sqlScript = serializer.acceptReadQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    final sqlScript = serializer.acceptUpdateQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  DatabaseDriverType get type => DatabaseDriverType.pgsql;

  @override
  TableBlueprint get blueprint => _PgSqlTableBlueprint();
}

class PgSqlPrimitiveSerializer extends SqliteSerializer {
  const PgSqlPrimitiveSerializer();
}

class _PgSqlTableBlueprint implements TableBlueprint {
  final List<String> _statements = [];

  void char(String name, {String? defaultValue, bool nullable = false, int length = 10}) {
    final sb = StringBuffer()..write('$name CHAR ($length)');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }

    _statements.add(sb.toString());
  }

  void varChar(String name, {String? defaultValue, bool nullable = false, int length = 10}) {
    final sb = StringBuffer()..write('$name VARCHAR ($length)');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }
  }

  @override
  void blob(String name, {String? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name BYTEA');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }
    _statements.add(sb.toString());
  }

  @override
  void boolean(String name, {bool? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name BOOLEAN');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }

    _statements.add(sb.toString());
  }

  @override
  String createScript(String tableName) {
    return 'CREATE TABLE $tableName (${_statements.join(', ')});';
  }

  @override
  void datetime(String name, {bool? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name TIMESTAMP');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }

    _statements.add(sb.toString());
  }

  @override
  void double(String name, {num? defaultValue, bool nullable = false}) {
    String columnDefinition = "$name DOUBLE PRECISION";
    if (defaultValue != null) {
      columnDefinition += " DEFAULT $defaultValue";
    }
    if (!nullable) {
      columnDefinition += " NOT NULL";
    }
    _statements.add(columnDefinition);
  }

  @override
  String dropScript(String tableName) {
    return 'DROP TABLE $tableName';
  }

  @override
  void float(String name, {num? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name REAL');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }
    _statements.add(sb.toString());
  }

  @override
  void id({bool autoIncrement = true}) {
    final sb = StringBuffer()..write('id');
    sb.write(autoIncrement ? "SERIAL PRIMARY KEY" : "INTEGER PRIMARY KEY");
    _statements.add(sb.toString());
  }

  @override
  void integer(String name, {Integer type = Integer.integer, num? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name INTEGER');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }

    _statements.add(sb.toString());
  }

  @override
  String renameScript(String fromName, String toName) {
    return 'ALTER TABLE $fromName RENAME TO $toName';
  }

  @override
  void string(String name, {String? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name TEXT');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }
  }

  @override
  void timestamp(String name, {String? defaultValue, bool nullable = false}) {
    final sb = StringBuffer()..write('$name TIMESTAMP');
    if (nullable) {
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    } else {
      sb.write(' NOT NULL');
    }
    _statements.add(sb.toString());
  }

  @override
  void timestamps({String createdAt = entityCreatedAtColumnName, String updatedAt = entityUpdatedAtColumnName}) {
    timestamp(createdAt);
    timestamp(updatedAt);
  }
}
