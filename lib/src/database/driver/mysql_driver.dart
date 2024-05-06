import 'package:meta/meta.dart';
import 'package:mysql_client/mysql_client.dart';
import '../../migration.dart';
import '../entity/entity.dart';
import '../../query/query.dart';

import '../../primitives/serializer.dart';
import 'driver.dart';
import 'sqlite_driver.dart';

final _serializer = MySqlPrimitiveSerializer();

const _mysqlTypeConverters = <EntityTypeConverter>[dateTimeConverter];

final class MySqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  final DatabaseDriverType _type;

  late MySQLConnection _dbConnection;

  int get portToUse => config.port ?? 3306;

  MySqlDriver(this.config, this._type) {
    assert([DatabaseDriverType.mysql, DatabaseDriverType.mariadb].contains(config.driver));
    assert(config.host != null, 'Host is required');
  }

  @override
  Future<DatabaseDriver> connect({int? maxConnections, bool? singleConnection}) async {
    assert(maxConnections == null, '${_type.name} max connections not yet supported');
    final secure = config.secure ?? false;

    if (secure) {
      assert(config.username != null, 'Username is required when :secure true');
      assert(config.password != null, 'Password is required when :secure true');
    }

    _dbConnection = await MySQLConnection.createConnection(
      host: config.host!,
      port: portToUse,
      secure: secure,
      userName: config.username ?? '',
      password: config.password ?? '',
      databaseName: config.database,
    );
    await _dbConnection.connect();
    return this;
  }

  @override
  Future<void> disconnect() async {
    if (!_dbConnection.connected) return;
    return _dbConnection.close();
  }

  @override
  bool get isOpen => _dbConnection.connected;

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) async {
    if (!isOpen) await connect();
    final result = await _dbConnection.execute(script);
    return result.rows.map((e) => e.typedAssoc()).toList();
  }

  @override
  Future<dynamic> execute(String script) => rawQuery(script);

  @override
  Future<List<Map<String, dynamic>>> query(ReadQuery query) {
    final sql = _serializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) async {
    final sql = _serializer.acceptDeleteQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) async {
    final result = await _dbConnection.execute(_serializer.acceptUpdateQuery(query), query.data);
    return result.rows.map((e) => e.typedAssoc()).toList();
  }

  @override
  Future<int> insert(InsertQuery query) async {
    final result = await _dbConnection.execute(_serializer.acceptInsertQuery(query), query.data);
    return result.lastInsertID.toInt();
  }

  @override
  Future<void> insertMany(InsertManyQuery query) async {
    return await _dbConnection.transactional((conn) => _MysqlTransactor(conn, type).insertMany(query));
  }

  @override
  Future<bool> hasTable(String tableName) async {
    final sql =
        'SELECT 1 FROM information_schema.tables WHERE table_schema = ${wrapString(config.database)} AND table_name = ${wrapString(tableName)} LIMIT 1';
    final result = await rawQuery(sql);
    return result.isNotEmpty;
  }

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) func) =>
      _dbConnection.transactional((txn) => func(_MysqlTransactor(txn, type)));

  @override
  DatabaseDriverType get type => _type;

  @override
  TableBlueprint get blueprint => MySqlDriverTableBlueprint();

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  List<EntityTypeConverter> get typeconverters => _mysqlTypeConverters;
}

class _MysqlTransactor extends DriverTransactor {
  final MySQLConnection _dbConn;

  @override
  final DatabaseDriverType type;

  _MysqlTransactor(this._dbConn, this.type);

  @override
  Future<dynamic> execute(String script) => rawQuery(script);

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) async {
    final rows = (await _dbConn.execute(script)).rows;
    if (rows.isEmpty) return [];
    return rows.map((e) => e.typedAssoc()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> query(ReadQuery query) {
    final sql = _serializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<void> delete(DeleteQuery query) async {
    final sql = _serializer.acceptDeleteQuery(query);
    await rawQuery(sql);
  }

  @override
  Future<void> update(UpdateQuery query) async {
    await _dbConn.execute(_serializer.acceptUpdateQuery(query), query.data);
  }

  @override
  Future<int> insert(InsertQuery query) async {
    final result = await _dbConn.execute(_serializer.acceptInsertQuery(query), query.data);
    return result.lastInsertID.toInt();
  }

  @override
  Future<void> insertMany(InsertManyQuery query) async {
    final sql = _serializer.acceptInsertManyQuery(query);
    for (final value in query.values) {
      await _dbConn.execute(sql, value);
    }
  }

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  List<EntityTypeConverter> get typeconverters => _mysqlTypeConverters;
}

@protected
class MySqlDriverTableBlueprint extends SqliteTableBlueprint {
  @override
  PrimitiveSerializer get szler => _serializer;

  @override
  void id({String name = 'id', String? type, bool autoIncrement = true}) {
    type ??= 'INT';
    final sb = StringBuffer()..write('${_serializer.escapeStr(name)} $type NOT NULL PRIMARY KEY');
    if (autoIncrement) sb.write(' AUTO_INCREMENT');
    statements.add(sb.toString());
  }

  @override
  void string(String name, {bool nullable = false, String? defaultValue, int length = 255}) {
    statements.add(makeColumn(name, 'VARCHAR($length)', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void datetime(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(makeColumn(name, 'DATETIME', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void timestamp(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(makeColumn(name, 'TIMESTAMP', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void date(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(makeColumn(name, 'DATE', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void time(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(makeColumn(name, 'TIME', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void boolean(String name, {bool nullable = false, bool? defaultValue}) {
    statements.add(makeColumn(name, 'BOOLEAN', nullable: nullable, defaultValue: defaultValue));
  }

  /// NUMERIC TYPES
  /// ----------------------------------------------------------------

  @override
  void float(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'FLOAT(${precision ?? 10}, ${scale ?? 0})';
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void double(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'DOUBLE(${precision ?? 10}, ${scale ?? 0})';
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void tinyInt(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(makeColumn(name, 'TINYINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void smallInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(makeColumn(name, 'SMALLINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void mediumInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(makeColumn(name, 'MEDIUMINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void bigInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(makeColumn(name, 'BIGINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void decimal(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'DECIMAL(${precision ?? 10}, ${scale ?? 0})';
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void numeric(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'NUMERIC(${precision ?? 10}, ${scale ?? 0})';
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void bit(String name, {bool nullable = false, int? defaultValue}) {
    statements.add(makeColumn(name, 'BIT', nullable: nullable, defaultValue: defaultValue));
  }

  /// STRING TYPES
  /// ----------------------------------------------------------------

  String _getStringType(String type, {String? charset, String? collate}) {
    final sb = StringBuffer()..write(type);
    if (charset != null) sb.write(' CHARACTER SET $charset');
    if (collate != null) sb.write(' COLLATE $collate');
    return sb.toString();
  }

  /// BLOB typs cannot have default values see here: https://dev.mysql.com/doc/refman/8.0/en/blob.html
  @override
  void blob(String name, {bool nullable = false, defaultValue}) {
    final type = _getStringType('BLOB');
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: null));
  }

  /// TEXT type cannot have default values see here: https://dev.mysql.com/doc/refman/8.0/en/blob.html
  @override
  void text(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    final type = _getStringType('TEXT($length)', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: null));
  }

  @override
  void longText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('LONGTEXT', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void mediumText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('MEDIUMTEXT', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void tinyText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('TINYTEXT', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void char(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    final type = _getStringType('CHAR($length)', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void varchar(String name,
      {bool nullable = false, String? defaultValue, int length = 255, String? charset, String? collate}) {
    final type = _getStringType('VARCHAR($length)', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void enums(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('ENUM(${values.join(', ')})', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void set(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('SET(${values.join(', ')})', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void binary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int size = 1}) {
    final type = _getStringType('BINARY($size)', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void varbinary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int size = 1}) {
    final type = _getStringType('VARBINARY($size)', charset: charset, collate: collate);
    statements.add(makeColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }
}

@protected
class MySqlPrimitiveSerializer extends SqliteSerializer {
  const MySqlPrimitiveSerializer();

  @override
  String acceptInsertQuery(InsertQuery query) {
    final keys = query.data.keys;
    final parameters = keys.map((e) => ':$e').join(', ');
    return 'INSERT INTO ${query.tableName} (${keys.join(', ')}) VALUES ($parameters)$terminator';
  }

  @override
  String acceptInsertManyQuery(InsertManyQuery query) {
    final keys = query.values.first.keys;
    final parameters = keys.map((e) => ':$e').join(', ');
    return 'INSERT INTO ${query.tableName} (${keys.join(', ')}) VALUES ($parameters)$terminator';
  }

  @override
  String acceptUpdateQuery(UpdateQuery query) {
    final queryBuilder = StringBuffer();

    final fields = query.data.keys.map((e) => '${escapeStr(e)} = :$e').join(', ');

    queryBuilder.write('UPDATE ${escapeStr(query.tableName)}');

    queryBuilder
      ..write(' SET $fields')
      ..write(' WHERE ${acceptWhereClause(query.whereClause)}')
      ..write(terminator);

    return queryBuilder.toString();
  }
}
