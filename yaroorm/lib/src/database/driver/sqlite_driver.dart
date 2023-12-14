import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../table.dart';
import 'driver.dart';

class SqliteDriver implements DatabaseDriver {
  final DatabaseConnection config;

  Database? _database;

  SqliteDriver(this.config);

  @override
  Future<void> connect() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    _database = await databaseFactory.openDatabase(
      config.database,
      options: OpenDatabaseOptions(onOpen: (db) async {
        // Enable foreign key support
        if (config.dbForeignKeys) {
          await db.execute('PRAGMA foreign_keys = ON;');
        }
      }),
    );
  }

  @override
  Future<void> disconnect() async {
    if (!isOpen) return;
    await _database!.close();
    _database = null;
  }

  @override
  bool get isOpen => _database?.isOpen ?? false;

  @override
  String get database => config.database;

  @override
  DatabaseDriverType get type => DatabaseDriverType.sqlite;

  @override
  TableBlueprint get blueprint => _SqliteTableBlueprint();

  @override
  Future execute(String script) async {
    final db = _database;
    if (!isOpen || db == null) throw Exception('Database is not open');
    await db.execute(script);
  }
}

class _SqliteTableBlueprint implements TableBlueprint {
  final List<String> _statements = [];

  @override
  void id() {
    _statements.add('id INTEGER PRIMARY KEY');
  }

  @override
  void string(String name) {
    _statements.add('$name TEXT');
  }

  @override
  void double(String name) {
    _statements.add('$name REAL');
  }

  @override
  void float(String name) {
    _statements.add('$name REAL');
  }

  @override
  void integer(String name) {
    _statements.add('$name INTEGER');
  }

  @override
  void blob(String name) {
    _statements.add('$name BLOB');
  }

  @override
  void boolean(String name) {
    _statements.add('$name INTEGER');
  }

  @override
  void datetime(String name) {
    _statements.add('$name DATETIME');
  }

  @override
  void timestamp(String name) {
    _statements.add('$name DATETIME');
  }

  @override
  void timestamps({String createdAt = 'created_at', String updatedAt = 'updated_at'}) {
    _statements.add('$createdAt DATETIME');
    _statements.add('$updatedAt DATETIME');
  }

  @override
  String createScript(String tableName) {
    return 'CREATE TABLE $tableName (${_statements.join(', ')});';
  }

  @override
  String dropScript(String tableName) {
    return 'DROP TABLE IF EXISTS $tableName;';
  }
}
