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
  String get database => config.database;

  @override
  DatabaseDriverType get type => DatabaseDriverType.sqlite;

  @override
  TableBlueprint newTable(String tableName) => _SqliteTableBlueprint(tableName);

  @override
  bool get isOpen => _database?.isOpen ?? false;
}

class _SqliteTableBlueprint extends TableBlueprint {
  _SqliteTableBlueprint(String tableName) : super(tableName);

  @override
  TableColumn id() {
    throw UnimplementedError();
  }

  @override
  TableColumn password(String name) {
    throw UnimplementedError();
  }

  @override
  TableColumn rememberToken() {
    throw UnimplementedError();
  }

  @override
  TableColumn string(String name) {
    throw UnimplementedError();
  }

  @override
  TableColumn timestamp(String name) {
    throw UnimplementedError();
  }

  @override
  TableColumn timestamps() {
    throw UnimplementedError();
  }
}
