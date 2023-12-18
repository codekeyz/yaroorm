// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

import 'driver/driver.dart';
import 'entity.dart';

class Id {}

enum Integer { smallint, integer, bigint }

abstract interface class TableBlueprint {
  void id({bool autoIncrement = true});

  void string(
    String name, {
    String? defaultValue,
    bool nullable = false,
  });

  void integer(
    String name, {
    Integer type = Integer.integer,
    num? defaultValue,
    bool nullable = false,
  });

  void double(
    String name, {
    num? defaultValue,
    bool nullable = false,
  });

  void float(
    String name, {
    num? defaultValue,
    bool nullable = false,
  });

  void boolean(
    String name, {
    bool? defaultValue,
    bool nullable = false,
  });

  void timestamp(
    String name, {
    String? defaultValue,
    bool nullable = false,
  });

  void datetime(
    String name, {
    bool? defaultValue,
    bool nullable = false,
  });

  void blob(
    String name, {
    String? defaultValue,
    bool nullable = false,
  });

  void timestamps({
    String createdAt = entityCreatedAtColumnName,
    String updatedAt = entityUpdatedAtColumnName,
  });

  @protected
  String createScript(String tableName);

  @protected
  String dropScript(String tableName);

  @protected
  String renameScript(String fromName, String toName);
}

typedef TableBluePrintFunc = TableBlueprint Function(TableBlueprint $table);

class Schema {
  final String tableName;
  final TableBluePrintFunc? _bluePrintFunc;

  String? _scriptname;

  Schema._(this.tableName, this._bluePrintFunc);

  String toScript(TableBlueprint $table) =>
      _bluePrintFunc!.call($table).createScript(tableName);

  static Schema create(String name, TableBluePrintFunc func) =>
      Schema._(name, func);

  static Schema dropIfExists(String name) => _DropSchema(name);

  static Schema rename(String from, String to) => _RenameSchema(from, to);
}

class _DropSchema extends Schema {
  _DropSchema(String name) : super._(name, null);

  @override
  String toScript(TableBlueprint $table) => $table.dropScript(tableName);
}

class _RenameSchema extends Schema {
  final String newName;

  _RenameSchema(String from, this.newName) : super._(from, null);

  @override
  String toScript(TableBlueprint $table) =>
      $table.renameScript(tableName, newName);
}

abstract class Migration {
  const Migration();

  String get name => runtimeType.toString().snakeCase;

  void up(List<Schema> $actions);

  void down(List<Schema> $actions);
}

List<Schema> _accumulateSchemas(Function(List<Schema> schemas) func) {
  final result = <Schema>[];
  func(result);
  return result;
}

Future<void> processMigrationCmd(
  String cmd,
  List<Migration> migrations,
  DatabaseDriver driver, {
  List<String>? cmdArguments,
}) async {
  cmd = cmd.toLowerCase();

  final resultingSchemas = <Schema>[];

  for (final migration in migrations) {
    final result = switch (cmd) {
      'migrate' => _accumulateSchemas(migration.up),
      'migrate:reset' => _accumulateSchemas(migration.down),
      _ => throw UnsupportedError(cmd),
    };
    result.forEach((schema) => schema._scriptname = migration.name);
    resultingSchemas.addAll(result);
  }

  print('------- Starting database migration --\n');
  for (final schema in resultingSchemas) {
    print('-x executing ${schema._scriptname}');

    final script = schema.toScript(driver.blueprint);
    await driver.execute(script);
  }
  print('------- Completed migration  ✅ ------\n');
}
