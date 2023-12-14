import '../reflection/reflection.dart';
import 'driver/driver.dart';

abstract interface class TableBlueprint {
  void id();

  void string(String name);

  void integer(String name);

  void double(String name);

  void float(String name);

  void boolean(String name);

  void timestamp(String name);

  void datetime(String name);

  void blob(String name);

  void timestamps({String createdAt = 'created_at', String updatedAt = 'updated_at'});

  List<String> get statements;
}

class Schema {
  final String name;
  final TableBluePrintFunc? _bluePrintFunc;

  String toScript(TableBlueprint $table) {
    _bluePrintFunc!.call($table);
    return 'CREATE TABLE $name (${$table.statements.join(', ')})';
  }

  const Schema._(this.name, this._bluePrintFunc);

  static Schema create(String name, TableBluePrintFunc func) => Schema._(name, func);

  static Schema dropIfExists(String name) => _DropSchema(name);
}

class _DropSchema extends Schema {
  const _DropSchema(String name) : super._(name, null);

  @override
  String toScript(TableBlueprint $table) => 'DROP TABLE IF EXISTS $name';
}

@migration
abstract class Migration {
  void up(List<dynamic> $actions);

  void down(List<dynamic> $actions);
}
