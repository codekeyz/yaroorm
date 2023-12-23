import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:yaroorm/src/database/driver/mysql_driver.dart';
import 'package:yaroorm/src/query/primitives/serializer.dart';
import 'package:yaroorm/yaroorm.dart';

import 'sqlite_driver.dart' show SqliteSerializer;

final _primitiveSerializer = PgSqlPrimitiveSerializer();

class PostgreSqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  late pg.Connection db;

  PostgreSqlDriver(this.config);

  static const _serializer = PgSqlPrimitiveSerializer();

  @override
  Future<DatabaseDriver> connect({int? maxConnections, bool? singleConnection, bool? secure}) async {
    assert(maxConnections == null, 'Postgres max connections not supported');
    secure ??= false;

    if (secure == true) {
      assert(config.username != null, 'Username is required when :secure true');
      assert(config.password != null, 'Password is required when :secure true');
    }


    db = await pg.Connection.open(pg.Endpoint(
      host: config.host!,
      database: config.database,
      username: config.username,
      password: config.password,
      port: config.port == null ? 5432 : config.port!,
    ));
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) {
    final sqlScript = serializer.acceptDeleteQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<void> disconnect() async {
    if(!isOpen) return;
    await db.close();
  }

  Future<List<Map<String, dynamic>>> _execRawQuery(String script) async {
    if(!isOpen) await connect();
    final result = await db.execute(script);
    return result.map((e) => e.toColumnMap()).toList();
  }

  @override
  Future execute(String script) => rawQuery(script);

  @override
  Future<int> insert(InsertQuery query) async {
    final sql = _primitiveSerializer.acceptInsertQuery(query);
    if (!isOpen) await connect();
    final result = await db.execute(sql);
    return result.affectedRows;
  }

  @override
  bool get isOpen => db.isOpen;

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
  TableBlueprint get blueprint => PgSqlTableBlueprint();

  @override
  Future<bool> hasTable(String tableName) async {
    final result = await db.execute(
        '''SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name='$tableName')''');
    if (result.isEmpty) return false;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) {
    return _execRawQuery(script);
  }

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) func)  {
    return db.runTx((txn) async => func(_PgSqlDriverTransactor(txn)));
  }

  @override
  Future insertMany(InsertManyQuery query) {
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    return rawQuery(sql);
  }
}

class _PgSqlDriverTransactor extends DriverTransactor {
  final pg.TxSession txn;

  _PgSqlDriverTransactor(this.txn);

  @override
  Future<List<Object?>> commit() {
    throw UnsupportedError('Commit not supported for Postgres Driver');
  }

  @override
  Future<void> delete(DeleteQuery query)async {
    final sql = _primitiveSerializer.acceptDeleteQuery(query);
    await rawQuery(sql);
  }

  @override
  Future execute(String script) => rawQuery(script);

  @override
  Future insert(InsertQuery query) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  Future insertMany(InsertManyQuery query) {
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> query(Query query) {
    final sql = _primitiveSerializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script)async {
    final result = await txn.execute(script);
    return result.map((e) => e.toColumnMap()).toList();
  }

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;

  @override
  Future<void> update(UpdateQuery query)async {
    final sql = _primitiveSerializer.acceptUpdateQuery(query);
    await rawQuery(sql);
  }

}

@protected
class PgSqlPrimitiveSerializer extends SqliteSerializer  {
  const PgSqlPrimitiveSerializer();
}

@protected
class PgSqlTableBlueprint extends MySqlDriverTableBlueprint {}
