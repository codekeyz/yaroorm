import 'driver/driver.dart';

class TableColumn {
  final String name;
  final String dataType;
  final bool primaryKey;
  final bool primaryKeyAutoIncrement;

  TableColumn(
    this.name,
    this.dataType, {
    this.primaryKey = false,
    this.primaryKeyAutoIncrement = false,
  });
}

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
}

abstract class Migration {
  void up(List<dynamic> $actions);

  void down(List<dynamic> $actions);
}

class Schema {
  final String name;
  final TableBluePrintFunc? _bluePrint;
  final bool _dropIfExists;

  // String get createTableStatement => 'CREATE TABLE $name (${statements.join(', ')})';

  const Schema._(
    this.name,
    this._bluePrint, {
    bool shouldDrop = false,
  }) : _dropIfExists = shouldDrop;

  static Schema create(String name, TableBluePrintFunc func) => Schema._(name, func);

  static Schema dropIfExists(String name) => Schema._(name, null, shouldDrop: true);
}
