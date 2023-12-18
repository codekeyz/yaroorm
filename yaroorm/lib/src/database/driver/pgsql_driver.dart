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
  TableBlueprint get blueprint => throw UnimplementedError();
}

class PgSqlPrimitiveSerializer extends SqliteSerializer {
  const PgSqlPrimitiveSerializer();
}
