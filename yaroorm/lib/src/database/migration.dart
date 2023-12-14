// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'driver/driver.dart';
import 'table.dart';
import 'package:recase/recase.dart';

typedef TableBluePrintFunc = TableBlueprint Function(TableBlueprint $table);

class Schema {
  final String tableName;
  final TableBluePrintFunc? _bluePrintFunc;

  String? _scriptname;

  Schema._(this.tableName, this._bluePrintFunc);

  String toScript(TableBlueprint $table) =>
      _bluePrintFunc!.call($table).createScript(tableName);

  static Schema create(String name, TableBluePrintFunc func) => Schema._(name, func);

  static Schema dropIfExists(String name) => _DropSchema(name);
}

class _DropSchema extends Schema {
  _DropSchema(String name) : super._(name, null);

  @override
  String toScript(TableBlueprint $table) => $table.dropScript(tableName);
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
