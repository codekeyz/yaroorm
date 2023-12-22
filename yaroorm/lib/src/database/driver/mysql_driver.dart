import 'package:meta/meta.dart';
import 'package:yaroorm/src/database/migration.dart';
import 'package:yaroorm/src/query/primitives/serializer.dart';
import 'package:yaroorm/src/query/query.dart';

import 'driver.dart';
import 'sqlite_driver.dart';

final _tableBlueprint = MySqlDriverTableBlueprint();

final _primitiveSerializer = MySqlPrimitiveSerializer();

class MySqlDriver implements DatabaseDriver {
  final DatabaseConnection config;

  MySqlDriver(this.config);

  @override
  Future<DatabaseDriver> connect() {
    // TODO: implement connect
    throw UnimplementedError();
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
  Future<void> execute(String script) {
    // TODO: implement execute
    throw UnimplementedError();
  }

  @override
  Future<bool> hasTable(String tableName) {
    // TODO: implement hasTable
    throw UnimplementedError();
  }

  @override
  Future<int> insert(String tableName, Map<String, dynamic> data) {
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
  Future<List<Map<String, dynamic>>> rawQuery(String script) {
    // TODO: implement rawQuery
    throw UnimplementedError();
  }

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) transaction) {
    // TODO: implement transaction
    throw UnimplementedError();
  }

  @override
  DatabaseDriverType get type => DatabaseDriverType.mysql;

  @override
  TableBlueprint get blueprint => _tableBlueprint;

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    // TODO: implement update
    throw UnimplementedError();
  }
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
class MySqlPrimitiveSerializer extends SqliteSerializer {
  @override
  acceptDartValue(dartValue) {
    // TODO: implement acceptDartValue
    return super.acceptDartValue(dartValue);
  }
}
