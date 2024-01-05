import 'package:meta/meta.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:yaroorm/migration.dart';
import 'package:yaroorm/src/query/query.dart';

import '../../primitives/serializer.dart';
import 'driver.dart';
import 'sqlite_driver.dart';

final _primitiveSerializer = MySqlPrimitiveSerializer();

class MySqlDriver implements DatabaseDriver {
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
  Future<List<Map<String, dynamic>>> query(Query query) {
    final sql = _primitiveSerializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) async {
    final sql = _primitiveSerializer.acceptDeleteQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    final sql = _primitiveSerializer.acceptUpdateQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<int> insert(InsertQuery query) async {
    final sql = _primitiveSerializer.acceptInsertQuery(query);
    final result = await _dbConnection.execute(sql);
    return result.lastInsertID.toInt();
  }

  @override
  Future<void> insertMany(InsertManyQuery query) async {
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    await rawQuery(sql);
  }

  @override
  Future<bool> hasTable(String tableName) async {
    final sql =
        'SELECT 1 FROM information_schema.tables WHERE table_schema = ${wrapString(config.database)} AND table_name = ${wrapString(tableName)} LIMIT 1';
    final result = await rawQuery(sql);
    return result.isNotEmpty;
  }

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) func) {
    return _dbConnection.transactional((txn) => func(_MysqlTransactor(txn)));
  }

  @override
  DatabaseDriverType get type => _type;

  @override
  TableBlueprint get blueprint => MySqlDriverTableBlueprint();

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;
}

class _MysqlTransactor extends DriverTransactor {
  final MySQLConnection _dbConn;

  _MysqlTransactor(this._dbConn);

  @override
  Future<dynamic> execute(String script) => rawQuery(script);

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) async {
    final result = await _dbConn.execute(script);
    return result.rows.map((e) => e.assoc()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> query(Query query) {
    final sql = _primitiveSerializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<void> delete(DeleteQuery query) async {
    final sql = _primitiveSerializer.acceptDeleteQuery(query);
    await rawQuery(sql);
  }

  @override
  Future<void> update(UpdateQuery query) async {
    final sql = _primitiveSerializer.acceptUpdateQuery(query);
    await rawQuery(sql);
  }

  @override
  Future<int> insert(InsertQuery query) async {
    final sql = _primitiveSerializer.acceptInsertQuery(query);
    final result = await _dbConn.execute(sql);
    return result.lastInsertID.toInt();
  }

  @override
  Future<dynamic> insertMany(InsertManyQuery query) {
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    return rawQuery(sql);
  }

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;
}

@protected
class MySqlDriverTableBlueprint extends SqliteTableBlueprint {
  String _getColumn(String name, String type, {nullable = false, defaultValue}) {
    final sb = StringBuffer()..write('$name $type');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    return sb.toString();
  }

  @override
  void id({String name = 'id', String type = 'INTEGER', bool autoIncrement = true}) {
    final sb = StringBuffer()..write('$name $type NOT NULL PRIMARY KEY');
    if (autoIncrement) sb.write(' AUTO_INCREMENT');
    statements.add(sb.toString());
  }

  @override
  void string(String name, {bool nullable = false, String? defaultValue}) {
    statements.add(_getColumn(name, 'VARCHAR(255)', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void datetime(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(_getColumn(name, 'DATETIME', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void timestamp(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(_getColumn(name, 'TIMESTAMP', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void date(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(_getColumn(name, 'DATE', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void time(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(_getColumn(name, 'TIME', nullable: nullable, defaultValue: defaultValue));
  }

  /// NUMERIC TYPES
  /// ----------------------------------------------------------------

  @override
  void float(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'FLOAT(${precision ?? 10}, ${scale ?? 0})';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void double(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'DOUBLE(${precision ?? 10}, ${scale ?? 0})';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void tinyInt(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'TINYINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void smallInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'SMALLINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void mediumInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'MEDIUMINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void bigInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'BIGINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void decimal(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'DECIMAL(${precision ?? 10}, ${scale ?? 0})';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void numeric(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    final type = 'NUMERIC(${precision ?? 10}, ${scale ?? 0})';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void bit(String name, {bool nullable = false, int? defaultValue}) {
    statements.add(_getColumn(name, 'BIT', nullable: nullable, defaultValue: defaultValue));
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
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: null));
  }

  /// TEXT type cannot have default values see here: https://dev.mysql.com/doc/refman/8.0/en/blob.html
  @override
  void text(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    final type = _getStringType('TEXT($length)', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: null));
  }

  @override
  void longText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('LONGTEXT', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void mediumText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('MEDIUMTEXT', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void tinyText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('TINYTEXT', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void char(String name,
      {bool nullable = false, String? defaultValue, int size = 255, String? charset, String? collate, int length = 1}) {
    final type = _getStringType('CHAR($length)', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void varchar(String name,
      {bool nullable = false, String? defaultValue, int size = 255, String? charset, String? collate}) {
    final type = _getStringType('VARCHAR($size)', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void enums(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('ENUM(${values.join(', ')})', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void set(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('SET(${values.join(', ')})', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void binary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    final type = _getStringType('BINARY($length)', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void varbinary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    final type = _getStringType('VARBINARY($length)', charset: charset, collate: collate);
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }
}

@protected
class MySqlPrimitiveSerializer extends SqliteSerializer {}
