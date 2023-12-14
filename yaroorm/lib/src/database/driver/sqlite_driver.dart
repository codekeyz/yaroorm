import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../query/primitives.dart';
import '../../query/query.dart';
import '../migration.dart';
import 'driver.dart';

class SqliteDriver implements DatabaseDriver {
  final DatabaseConnection config;

  final QueryPrimitiveSerializer _queryPrimitiveSerializer =
      const _SqliteQueryPrimitiveSerializer();
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

  @override
  Future<T> query<T extends Entity>(RecordQueryInterface<T> query) async {
    final script = querySerializer.acceptQuery(query);
    throw Exception(script);
  }

  @override
  QueryPrimitiveSerializer get querySerializer => _queryPrimitiveSerializer;
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

  @override
  String renameScript(String oldName, String toName) {
    final StringBuffer renameScript = StringBuffer();
    renameScript
      ..writeln(
          'CREATE TABLE temp_info AS SELECT * FROM PRAGMA table_info(\'$oldName\');')
      ..writeln('CREATE TABLE temp_data AS SELECT * FROM $oldName;')
      ..writeln('CREATE TABLE $toName AS SELECT * FROM temp_data WHERE 1 = 0;')
      ..writeln('INSERT INTO $toName SELECT * FROM temp_data;')
      ..writeln('DROP TABLE temp_info; DROP TABLE temp_data;');
    return renameScript.toString();
  }
}

class _SqliteQueryPrimitiveSerializer implements QueryPrimitiveSerializer {
  const _SqliteQueryPrimitiveSerializer();

  @override
  String acceptQuery(RecordQueryInterface<Entity> query) {
    final queryBuilder = StringBuffer();

    final selectStatement = acceptSelect(query.fieldSelections.toList());
    queryBuilder.write(selectStatement);
    queryBuilder.write('FROM ${query.tableName}');

    final whereClause = query.whereClause;
    if (whereClause != null) {
      final whereStatement = acceptWhereClause(whereClause);
      queryBuilder.write(' $whereStatement');
    }

    return '${queryBuilder.toString()};';
  }

  @override
  String acceptSelect(List<String> fields) {
    return fields.isEmpty ? 'SELECT * ' : 'SELECT ${fields.join(', ')}';
  }

  String _whereValueToScript(WhereClauseValue clauseVal) {
    final value = clauseVal.value;
    final wrappedValue = switch (value.runtimeType) {
      const (int) => value,
      const (List<String>) =>
        '(${List<String>.from(value).map((e) => "'$e'").join(', ')})',
      const (List<int>) => '(${List<int>.from(value).join(', ')})',
      const (List<num>) => '(${List<num>.from(value).join(', ')})',
      const (List<double>) => '(${List<double>.from(value).join(', ')})',
      _ => "'$value'"
    };

    return '${clauseVal.field} ${clauseVal.condition} $wrappedValue';
  }

  @override
  String acceptWhereClause(WhereClause clause) {
    if (clause is CompositeWhereClause) {
      final whereBuilder = StringBuffer();
      whereBuilder.write('WHERE ${_whereValueToScript(clause.value)}');
      for (final subpart in clause.subparts) {
        whereBuilder.write(
            ' ${subpart.operator.name} ${_whereValueToScript(subpart.clause.value)}');
      }
      return whereBuilder.toString();
    }

    return 'WHERE ${_whereValueToScript(clause.value)}';
  }

  @override
  String acceptOrderBy(List<OrderBy> orderBys) {
    // TODO: implement acceptOrderBy
    throw UnimplementedError();
  }
}

void main() {
  final query = RecordQueryInterface('users')
      .where('username', '=', 'Chima')
      .or('lastname', '=', '23')
      .or('hello', '>', 22)
      .or('hello', '!=', 24059)
      .query;

  print(_SqliteQueryPrimitiveSerializer().acceptQuery(query));
}