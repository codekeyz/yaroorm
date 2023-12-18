import '../../access/access.dart';
import '../../access/primitives/serializer.dart';
import '../database.dart';

import 'package:postgres/postgres.dart' as pg;

class PostgreSqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  late pg.Connection? db;

  PostgreSqlDriver(this.config);

  @override
  TableBlueprint get blueprint => throw UnimplementedError();

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
  Future<void> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future execute(String script) {
    // TODO: implement execute
    throw UnimplementedError();
  }

  @override
  Future insert(String tableName, Map<String, dynamic> data) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  // TODO: implement isOpen
  bool get isOpen => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> query(Query query) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  // TODO: implement serializer
  PrimitiveSerializer get serializer => throw UnimplementedError();

  @override
  DatabaseDriverType get type => DatabaseDriverType.pgsql;

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    // TODO: implement update
    throw UnimplementedError();
  }
}

class _PostgreSqlTableBlueprint implements TableBlueprint {
  @override
  void blob(String name) {
    // TODO: implement blob
  }

  @override
  void boolean(String name) {
    // TODO: implement boolean
  }

  @override
  String createScript(String tableName) {
    // TODO: implement createScript
    throw UnimplementedError();
  }

  @override
  void datetime(String name) {
    // TODO: implement datetime
  }

  @override
  void double(String name) {
    // TODO: implement double
  }

  @override
  String dropScript(String tableName) {
    // TODO: implement dropScript
    throw UnimplementedError();
  }

  @override
  void float(String name) {
    // TODO: implement float
  }

  @override
  void id() {
    // TODO: implement id
  }

  @override
  void integer(String name) {
    // TODO: implement integer
  }

  @override
  String renameScript(String fromName, String toName) {
    // TODO: implement renameScript
    throw UnimplementedError();
  }

  @override
  void string(String name) {
    // TODO: implement string
  }

  @override
  void timestamp(String name) {
    // TODO: implement timestamp
  }

  @override
  void timestamps({
    String createdAt = entityCreatedAtColumnName,
    String updatedAt = entityUpdatedAtColumnName,
  }) {
    // TODO: implement timestamps
  }
}
