import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:yaroorm/migration.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../primitives/serializer.dart';
import 'mysql_driver.dart';
import 'sqlite_driver.dart' show SqliteSerializer;

final _primitiveSerializer = PgSqlPrimitiveSerializer();

class PostgreSqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  pg.Connection? db;

  PostgreSqlDriver(this.config);

  @override
  Future<DatabaseDriver> connect({int? maxConnections, bool? singleConnection, bool? secure}) async {
    assert(maxConnections == null, 'Postgres max connections not supported');
    secure ??= false;

    if (secure) {
      assert(config.username != null, 'Username is required when :secure true');
      assert(config.password != null, 'Password is required when :secure true');
    }

    db = await pg.Connection.open(
        pg.Endpoint(
          host: config.host!,
          database: config.database,
          username: config.username,
          password: config.password,
          port: config.port == null ? 5432 : config.port!,
        ),
        settings: pg.ConnectionSettings(sslMode: secure ? pg.SslMode.require : pg.SslMode.disable, timeZone: 'GMT'));
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) {
    final sqlScript = serializer.acceptDeleteQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<void> disconnect() async {
    if (!isOpen) return;
    await db?.close();
  }

  Future<List<Map<String, dynamic>>> _execRawQuery(String script) async {
    if (!isOpen) await connect();
    final result = await db?.execute(script);
    return result?.map((e) => e.toColumnMap()).toList() ?? [];
  }

  @override
  Future execute(String script) => rawQuery(script);

  @override
  Future<int> insert(InsertQuery query) async {
    if (!isOpen) await connect();
    var primaryKey = await getPrimaryKeyColumn(query.tableName);
    String sql = _primitiveSerializer.acceptInsertQuery(query);
    sql = '$sql RETURNING $primaryKey ;';
    final result = await db?.execute(sql);
    return result?[0][0] as int;
  }

  @override
  bool get isOpen => db?.isOpen ?? false;

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
  PrimitiveSerializer get serializer => _primitiveSerializer;

  @override
  DatabaseDriverType get type => DatabaseDriverType.pgsql;

  @override
  TableBlueprint get blueprint => PgSqlTableBlueprint();

  @override
  Future<bool> hasTable(String tableName) async {
    final result = await _execRawQuery(
        '''SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name='$tableName';''');
    if (result.isEmpty) return false;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) => _execRawQuery(script);

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) func) async {
    if (!isOpen) await connect();
    if (db == null) return Future.value();
    return db!.runTx((txn) async => func(_PgSqlDriverTransactor(txn)));
  }

  @override
  Future insertMany(InsertManyQuery query) async {
    if (!isOpen) await connect();
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    final result = await db?.execute(sql);
    return result?.expand((x) => x).toList();
  }

  Future<String> getPrimaryKeyColumn(String tableName) async {
    final result = await db?.execute('''SELECT pg_attribute.attname 
FROM pg_index, pg_class, pg_attribute, pg_namespace 
WHERE 
  pg_class.oid = '$tableName'::regclass AND 
  indrelid = pg_class.oid AND 
  nspname = 'public' AND 
  pg_class.relnamespace = pg_namespace.oid AND 
  pg_attribute.attrelid = pg_class.oid AND 
  pg_attribute.attnum = any(pg_index.indkey)
 AND indisprimary;''');

    return result?[0][0] as String;
  }
}

class _PgSqlDriverTransactor extends DriverTransactor {
  final pg.TxSession txn;

  _PgSqlDriverTransactor(this.txn);

  @override
  Future<void> delete(DeleteQuery query) async {
    final sql = _primitiveSerializer.acceptDeleteQuery(query);
    await rawQuery(sql);
  }

  @override
  Future execute(String script) => rawQuery(script);

  @override
  Future<int> insert(InsertQuery query) async {
    final sql = _primitiveSerializer.acceptInsertQuery(query);
    final result = await txn.execute(sql);
    return result.affectedRows;
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
  Future<List<Map<String, dynamic>>> rawQuery(String script) async {
    final result = await txn.execute(script);
    return result.map((e) => e.toColumnMap()).toList();
  }

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;

  @override
  Future<void> update(UpdateQuery query) async {
    final sql = _primitiveSerializer.acceptUpdateQuery(query);
    await rawQuery(sql);
  }
}

@protected
class PgSqlPrimitiveSerializer extends SqliteSerializer {
  const PgSqlPrimitiveSerializer();

  @override
  String acceptInsertQuery(InsertQuery query) {
    final data = query.values;
    final fields = data.keys.join(', ');
    final values = data.values.map((e) => acceptDartValue(e)).join(', ');
    return 'INSERT INTO ${query.tableName} ($fields) VALUES ($values)';
  }

  @override
  String acceptInsertManyQuery(InsertManyQuery query) {
    final data = query.values;
    final fields = data.first.keys.join(', ');
    final values = data.map((e) => '(${e.values.map((e) => acceptDartValue(e)).join(', ')})').join(', ');
    return 'INSERT INTO ${query.tableName} ($fields) VALUES $values $terminator';
  }
}

@protected
class PgSqlTableBlueprint extends MySqlDriverTableBlueprint {
  String _getColumn(String name, String type, {nullable = false, defaultValue}) {
    final sb = StringBuffer()..write('$name $type');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    return sb.toString();
  }

  @override
  void datetime(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(_getColumn(name, 'TIMESTAMP', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void blob(String name, {bool nullable = false, defaultValue}) {
    statements.add(_getColumn(name, "BYTEA", nullable: nullable, defaultValue: null));
  }

  @override
  void boolean(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'BOOLEAN', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void id({name = 'id', String? type, autoIncrement = true}) {
    type ??= 'SERIAL';

    final sb = StringBuffer()..write(name);
    sb.write(autoIncrement ? " $type PRIMARY KEY" : " INTEGER PRIMARY KEY");
    statements.add(sb.toString());
  }

  @override
  String renameScript(String fromName, String toName) {
    return 'ALTER TABLE $fromName RENAME TO $toName;';
  }

  @override
  void float(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'DOUBLE PRECISION';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void double(String name, {bool nullable = false, num? defaultValue, int? precision = 10, int? scale = 0}) {
    final type = 'NUMERIC($precision, $scale )';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void tinyInt(String name, {bool nullable = false, num? defaultValue}) {
    throw UnimplementedError('tinyInt not implemented for Postgres');
  }

  @override
  void mediumInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void text(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    statements.add(_getColumn(name, 'TEXT', nullable: nullable, defaultValue: null));
  }

  @override
  void longText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('longText not implemented for Postgres');
  }

  @override
  void mediumText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('mediumText not implemented for Postgres');
  }

  @override
  void tinyText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('tinyText not implemented for Postgres');
  }

  @override
  void binary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int size = 1}) {
    statements.add(_getColumn(name, "BYTEA", nullable: nullable, defaultValue: null));
  }

  @override
  void varbinary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int size = 1}) {
    throw UnimplementedError('varbinary not implemented for Postgres');
  }

  @override
  void enums(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('enums not implemented for Postgres');
  }

  @override
  void set(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('set not implemented for Postgres');
  }
}
