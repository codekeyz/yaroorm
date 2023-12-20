import 'package:postgres/postgres.dart' as pg;
import 'package:yaroorm/src/query/primitives/serializer.dart';
import 'package:yaroorm/yaroorm.dart';

import 'sqlite_driver.dart' show SqliteSerializer;

class PostgreSqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  late pg.Connection? db;

  PostgreSqlDriver(this.config);

  static const _serializer = PgSqlPrimitiveSerializer();

  @override
  Future<DatabaseDriver> connect() async {
    db = await pg.Connection.open(pg.Endpoint(
      host: config.host!,
      database: config.database,
      username: config.username,
      password: config.password,
      port: config.port == null ? 5432 : int.parse(config.port!),
    ));
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) {
    final sqlScript = serializer.acceptDeleteQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<void> disconnect() async {
    await db?.close();
  }

  Future<List<Map<String, dynamic>>> _execRawQuery(String script) async {
    final result = await db?.execute(script);
    if (result == null) return [];
    return result.map((e) => e.toColumnMap()).toList();
  }

  @override
  Future execute(String script) async {
    final result = await db?.execute(script);
    return result?.map((e) => e.toColumnMap()).toList();
  }

  @override
  Future<int> insert(String tableName, Map<String, dynamic> data) async {
    final queryBuilder = StringBuffer();

    queryBuilder.write('INSERT INTO  $tableName');
    queryBuilder.write(' (${data.keys.join(', ')})');
    queryBuilder.write(' VALUES (${data.values.join(', ')})');

    final result = await db?.execute(queryBuilder.toString());
    return result?.affectedRows ?? 0;
  }

  @override
  bool get isOpen => db != null && db!.isOpen;

  @override
  Future<List<Map<String, dynamic>>> query(Query query) async {
    final sqlScript = serializer.acceptReadQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    final sqlScript = serializer.acceptUpdateQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  DatabaseDriverType get type => DatabaseDriverType.pgsql;

  @override
  TableBlueprint get blueprint => _PgSqlTableBlueprint();

  @override
  Future<bool> hasTable(String tableName) async {
    final result = await db?.execute(
        '''SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name='$tableName')''');
    if (result == null || result.isEmpty) return false;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) {
    return _execRawQuery(script);
  }

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) transaction) async {
    db?.runTx(
      (session) {
        _execRawQuery('QUERY');
        return Future.value();
      },
    );
  }
}

class PgSqlPrimitiveSerializer extends SqliteSerializer {
  const PgSqlPrimitiveSerializer();
}

class _PgSqlTableBlueprint implements TableBlueprint {
  final List<String> _statements = [];

  void char(String name, {String? defaultValue, bool nullable = false, int length = 10}) {
    String charColumn = _getColumn(name, 'CHAR ($length)', nullable: nullable, defaultValue: defaultValue);
    _statements.add(charColumn);
  }

  void varChar(String name, {String? defaultValue, bool nullable = false, int length = 10}) {
    String varCharColumn = _getColumn(name, 'VARCHAR ($length)', nullable: nullable, defaultValue: defaultValue);
    _statements.add(varCharColumn);
  }

  @override
  void blob(String name, {String? defaultValue, bool nullable = false}) {
    String blobColumn = _getColumn(name, 'BYTEA', nullable: nullable, defaultValue: defaultValue);
    _statements.add(blobColumn);
  }

  @override
  void boolean(String name, {bool? defaultValue, bool nullable = false}) {
    String booleanColumn = _getColumn(name, 'BOOLEAN', nullable: nullable, defaultValue: defaultValue);
    _statements.add(booleanColumn);
  }

  @override
  String createScript(String tableName) {
    return 'CREATE TABLE $tableName (${_statements.join(', ')});';
  }

  @override
  void datetime(String name, {nullable = false, defaultValue}) {
    String dateTimeColumn = _getColumn(name, 'TIMESTAMP', nullable: nullable, defaultValue: defaultValue);
    _statements.add(dateTimeColumn);
  }

  @override
  void double(String name, {num? defaultValue, bool nullable = false}) {
    String doubleColumn = _getColumn(name, 'DOUBLE PRECISION', nullable: nullable, defaultValue: defaultValue);
    _statements.add(doubleColumn);
  }

  @override
  String dropScript(String tableName) {
    return 'DROP TABLE $tableName';
  }

  @override
  void float(String name, {num? defaultValue, bool nullable = false}) {
    String floatColumn = _getColumn(name, 'REAL', nullable: nullable, defaultValue: defaultValue);
    _statements.add(floatColumn);
  }

  @override
  void id({name = 'id', autoIncrement = true}) {
    final sb = StringBuffer()..write('id');
    sb.write(autoIncrement ? "SERIAL PRIMARY KEY" : "INTEGER PRIMARY KEY");
    _statements.add(sb.toString());
  }

  @override
  void integer(String name, {Integer type = Integer.integer, num? defaultValue, bool nullable = false}) {
    String integerColumn = _getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue);
    _statements.add(integerColumn);
  }

  @override
  String renameScript(String fromName, String toName) {
    return 'ALTER TABLE $fromName RENAME TO $toName';
  }

  @override
  void string(String name, {String? defaultValue, bool nullable = false}) {
    String stringColumn = _getColumn(name, 'TEXT', nullable: nullable, defaultValue: defaultValue);
    _statements.add(stringColumn);
  }

  @override
  void timestamp(String name, {nullable = false, defaultValue}) {
    String timeStampColumn = _getColumn(name, 'TIMESTAMP', nullable: nullable, defaultValue: defaultValue);
    _statements.add(timeStampColumn);
  }

  @override
  void timestamps({String createdAt = entityCreatedAtColumnName, String updatedAt = entityUpdatedAtColumnName}) {
    timestamp(createdAt);
    timestamp(updatedAt);
  }

  String _getColumn(String name, String type, {nullable = false, defaultValue}) {
    final sb = StringBuffer()..write('$name $type');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    return sb.toString();
  }
}
