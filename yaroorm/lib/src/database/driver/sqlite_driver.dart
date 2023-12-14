import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../migration.dart';
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
}

class _SqliteTableBlueprint implements TableBlueprint {
  final List<String> statements = [];

  @override
  void id() {
    statements.add('id INTEGER PRIMARY KEY');
  }

  @override
  void string(String name) {
    statements.add('$name TEXT');
  }

  @override
  void double(String name) {
    statements.add('$name REAL');
  }

  @override
  void float(String name) {
    statements.add('$name REAL');
  }

  @override
  void integer(String name) {
    statements.add('$name INTEGER');
  }

  @override
  void blob(String name) {
    statements.add('$name BLOB');
  }

  @override
  void boolean(String name) {
    statements.add('$name INTEGER');
  }

  @override
  void datetime(String name) {
    statements.add('$name DATETIME');
  }

  @override
  void timestamp(String name) {
    statements.add('$name DATETIME');
  }

  @override
  void timestamps({String createdAt = 'created_at', String updatedAt = 'updated_at'}) {
    statements.add('$createdAt DATETIME');
    statements.add('$updatedAt DATETIME');
  }
}
