import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

import 'entity.dart';

abstract interface class TableBlueprint {
  void id({String name = 'id', bool autoIncrement = true});

  void string(String name, {bool nullable = false, String? defaultValue});

  void boolean(String name, {bool nullable = false, bool? defaultValue});

  void timestamp(String name, {bool nullable = false, DateTime? defaultValue});

  void datetime(String name, {bool nullable = false, DateTime? defaultValue});

  void date(String name, {bool nullable = false, DateTime? defaultValue});

  void time(String name, {bool nullable = false, DateTime? defaultValue});

  void blob(String name, {bool nullable = false, String? defaultValue});

  void timestamps({String createdAt = entityCreatedAtColumnName, String updatedAt = entityUpdatedAtColumnName});

  /// NUMBER TYPES
  /// ----------------------------------------------------------------

  void integer(String name, {bool nullable = false, num? defaultValue});

  void double(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale});

  void float(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale});

  void tinyInt(String name, {bool nullable = false, num? defaultValue});

  void smallInteger(String name, {bool nullable = false, num? defaultValue});

  void mediumInteger(String name, {bool nullable = false, num? defaultValue});

  void bigInteger(String name, {bool nullable = false, num? defaultValue});

  void decimal(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale});

  void numeric(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale});

  void bit(String name, {bool nullable = false, int? defaultValue});

  /// STRING TYPES
  /// ----------------------------------------------------------------

  void text(
    String name, {
    int length = 1,
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void char(
    String name, {
    bool nullable = false,
    int length = 1,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void varchar(
    String name, {
    bool nullable = false,
    String? defaultValue,
    int size = 255,
    String? charset,
    String? collate,
  });

  void tinyText(
    String name, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void mediumText(
    String name, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void longText(
    String name, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void binary(
    String name, {
    bool nullable = false,
    int length = 1,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void varbinary(
    String name, {
    bool nullable = false,
    int length = 1,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void enums(
    String name,
    List<String> values, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  void set(
    String name,
    List<String> values, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
  });

  @protected
  String createScript(String tableName);

  @protected
  String dropScript(String tableName);

  @protected
  String renameScript(String fromName, String toName);
}

typedef TableBluePrintFunc = TableBlueprint Function(TableBlueprint table);

class Schema {
  final String tableName;
  final TableBluePrintFunc? _bluePrintFunc;

  Schema._(this.tableName, this._bluePrintFunc);

  String toScript(TableBlueprint table) => _bluePrintFunc!.call(table).createScript(tableName);

  static Schema create(String name, TableBluePrintFunc func) => Schema._(name, func);

  static Schema dropIfExists(String name) => _DropSchema(name);

  static Schema rename(String from, String to) => _RenameSchema(from, to);
}

class _DropSchema extends Schema {
  _DropSchema(String name) : super._(name, null);

  @override
  String toScript(TableBlueprint table) => table.dropScript(tableName);
}

class _RenameSchema extends Schema {
  final String newName;

  _RenameSchema(String from, this.newName) : super._(from, null);

  @override
  String toScript(TableBlueprint table) => table.renameScript(tableName, newName);
}

abstract class Migration {
  const Migration();

  String get name => runtimeType.toString().snakeCase;

  String get connection => 'default';

  void up(List<Schema> schemas);

  void down(List<Schema> schemas);
}
