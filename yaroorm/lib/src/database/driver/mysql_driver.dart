import 'package:yaroorm/src/database/migration.dart';
import 'package:yaroorm/src/query/primitives/serializer.dart';
import 'package:yaroorm/src/query/query.dart';

import 'driver.dart';
import 'sqlite_driver.dart';

class MySqlDriver implements DatabaseDriver {
  @override
  // TODO: implement blueprint
  TableBlueprint get blueprint => throw UnimplementedError();

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
  // TODO: implement serializer
  PrimitiveSerializer get serializer => throw UnimplementedError();

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) transaction) {
    // TODO: implement transaction
    throw UnimplementedError();
  }

  @override
  // TODO: implement type
  DatabaseDriverType get type => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    // TODO: implement update
    throw UnimplementedError();
  }
}

class MySqlDriverTableBlueprint extends SqliteTableBlueprint {
  String _getColumn(String name, String type, {nullable = false, defaultValue}) {
    final sb = StringBuffer()..write('$name $type');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    return sb.toString();
  }

  /// STRING TYPES
  /// ----------------------------------------------------------------

  String _getStringType(String type, {String? charset, String? collate}) {
    final sb = StringBuffer()..write(type);
    if (charset != null) sb.write(' CHARACTER SET $charset');
    if (collate != null) sb.write(' COLLATE $collate');
    return sb.toString();
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
  void text(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final type = _getStringType('TEXT', charset: charset, collate: collate);
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
