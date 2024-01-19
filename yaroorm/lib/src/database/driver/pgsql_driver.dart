import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:sqflite_common/sql.dart';
import 'package:yaroorm/migration.dart';
import 'package:yaroorm/src/database/driver/mysql_driver.dart';
import 'package:yaroorm/src/primitives/serializer.dart';
import 'package:yaroorm/src/primitives/where.dart';
import 'package:yaroorm/yaroorm.dart';

final _primitiveSerializer = PgSqlPrimitiveSerializer();

class PostgreSqlDriver implements DatabaseDriver {
  final DatabaseConnection config;
  pg.Connection? db;

  PostgreSqlDriver(this.config);

  @override
  Future<DatabaseDriver> connect({int? maxConnections, bool? singleConnection, bool? secure}) async {
    assert(maxConnections == null, 'Postgres max connections not supported');
    secure ??= false;

    if (secure) {
      assert(config.username != null, 'Username is required when :secure true');
      assert(config.password != null, 'Password is required when :secure true');
    }

    db = await pg.Connection.open(
        pg.Endpoint(
          host: config.host!,
          database: config.database,
          username: config.username,
          password: config.password,
          port: config.port == null ? 5432 : config.port!,
        ),
        settings: pg.ConnectionSettings(
            sslMode: (config.secure ?? false) ? pg.SslMode.require : pg.SslMode.disable, timeZone: config.timeZone));
    return this;
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) {
    final sqlScript = serializer.acceptDeleteQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<void> disconnect() async {
    if (!isOpen) return;
    await db?.close();
  }

  Future<List<Map<String, dynamic>>> _execRawQuery(String script, {Map<String, dynamic>? parameters}) async {
    parameters ??= {};
    if (!isOpen) await connect();
    final result = await db?.execute(pg.Sql.named(script), parameters: parameters);
    return result?.map((e) => e.toColumnMap()).toList() ?? [];
  }

  @override
  Future execute(String script) => rawQuery(script);

  @override
  Future<int?> insert(InsertQuery query) async {
    if (!isOpen) await connect();
    final primaryKey = await _getPrimaryKeyColumn(query.tableName);
    final sql = _primitiveSerializer.acceptInsertQuery(query, primaryKey: primaryKey);
    final result = await db?.execute(sql);
    return int.tryParse((result?.first.first.toString() ?? ''));
  }

  @override
  bool get isOpen => db?.isOpen ?? false;

  @override
  Future<List<Map<String, dynamic>>> query(Query query) async {
    final sqlScript = serializer.acceptReadQuery(query);
    return _execRawQuery(sqlScript);
  }

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) {
    return _execRawQuery(serializer.acceptUpdateQuery(query), parameters: query.data);
  }

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;

  @override
  DatabaseDriverType get type => DatabaseDriverType.pgsql;

  @override
  TableBlueprint get blueprint => PgSqlTableBlueprint();

  @override
  Future<bool> hasTable(String tableName) async {
    final result = await _execRawQuery(
        '''SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name=@tableName;''',
        parameters: {'tableName': tableName});
    if (result.isEmpty) return false;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) => _execRawQuery(script);

  @override
  Future<void> transaction(void Function(DriverTransactor transactor) func) async {
    if (!isOpen) await connect();
    if (db == null) return Future.value();
    return db!.runTx((txn) async => func(_PgSqlDriverTransactor(txn)));
  }

  @override
  Future insertMany(InsertManyQuery query) async {
    if (!isOpen) await connect();
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    final result = await db?.execute(sql);
    return result?.expand((x) => x).toList();
  }

  Future<String> _getPrimaryKeyColumn(String tableName) async {
    final result = await db?.execute('''SELECT pg_attribute.attname 
FROM pg_index, pg_class, pg_attribute, pg_namespace 
WHERE 
  pg_class.oid = '"$tableName"'::regclass AND 
  indrelid = pg_class.oid AND 
  nspname = 'public' AND 
  pg_class.relnamespace = pg_namespace.oid AND 
  pg_attribute.attrelid = pg_class.oid AND 
  pg_attribute.attnum = any(pg_index.indkey)
 AND indisprimary;''');

    return result?[0][0] as String;
  }

  @override
  List<EntityTypeConverter> get typeconverters => [booleanConverter];
}

class _PgSqlDriverTransactor extends DriverTransactor {
  final pg.TxSession txn;

  _PgSqlDriverTransactor(this.txn);

  @override
  Future<void> delete(DeleteQuery query) async {
    final sql = _primitiveSerializer.acceptDeleteQuery(query);
    await rawQuery(sql);
  }

  @override
  Future execute(String script) => rawQuery(script);

  @override
  Future<int> insert(InsertQuery query) async {
    final sql = _primitiveSerializer.acceptInsertQuery(query);
    final result = await txn.execute(
      sql,
    );
    return result.affectedRows;
  }

  @override
  Future insertMany(InsertManyQuery query) {
    final sql = _primitiveSerializer.acceptInsertManyQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> query(Query query) {
    final sql = _primitiveSerializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) async {
    final result = await txn.execute(script);
    return result.map((e) => e.toColumnMap()).toList();
  }

  @override
  PrimitiveSerializer get serializer => _primitiveSerializer;

  @override
  Future<void> update(UpdateQuery query) async {
    final sql = _primitiveSerializer.acceptUpdateQuery(query);
    await rawQuery(sql);
  }
}

@protected
class PgSqlPrimitiveSerializer extends MySqlPrimitiveSerializer {
  const PgSqlPrimitiveSerializer();

  @override
  String acceptReadQuery(Query query) {
    final queryBuilder = StringBuffer();

    /// SELECT
    final selectStatement = acceptSelect(query.fieldSelections.toList());
    queryBuilder.write(selectStatement);
    queryBuilder.write('FROM "${escapeName(query.tableName)}"');

    /// WHERE
    final clauses = query.whereClauses;
    if (clauses.isNotEmpty) {
      final sb = StringBuffer();

      final hasDifferentOperators = clauses.map((e) => e.operators).reduce((val, e) => val..addAll(e)).length > 1;

      for (final clause in clauses) {
        final result = acceptWhereClause(clause, canGroup: hasDifferentOperators);
        if (sb.isEmpty) {
          sb.write(result);
        } else {
          sb.write(' ${clause.operator.name} $result');
        }
      }

      queryBuilder.write(' WHERE $sb');
    }

    /// ORDER BY
    final orderBys = query.orderByProps;
    if (orderBys.isNotEmpty) {
      queryBuilder.write(' ORDER BY ${acceptOrderBy(orderBys.toList())}');
    }

    /// LIMIT
    final limit = query.limit;
    if (limit != null) {
      queryBuilder.write(' LIMIT ${acceptLimit(limit)}');
    }
    return '${queryBuilder.toString()}$terminator';
  }

  @override
  String acceptInsertQuery(InsertQuery query, {String? primaryKey}) {
    final keys = query.data.keys.map((e) => '"$e"').toList();
    final parameters = query.data.values.map((e) => "'$e'").join(', ');
    var sql = 'INSERT INTO "${escapeName(query.tableName)}" (${keys.join(', ')}) VALUES ($parameters)';
    if (primaryKey == null) return '$sql$terminator';
    return '$sql RETURNING "$primaryKey"$terminator';
  }

  @override
  String acceptUpdateQuery(UpdateQuery query) {
    final queryBuilder = StringBuffer();

    final fields = query.data.keys.map((e) => '$e = @$e').join(', ');

    queryBuilder.write('UPDATE "${escapeName(query.tableName)}"');

    queryBuilder
      ..write(' SET $fields')
      ..write(' WHERE ${acceptWhereClause(query.whereClause)}')
      ..write(terminator);

    return queryBuilder.toString();
  }

  @override
  String acceptInsertManyQuery(InsertManyQuery query) {
    final fields = query.values.first.keys.map((e) => '"$e"').join(', ');
    final values = query.values.map((dataMap) {
      final values = dataMap.values.map((value) => "'$value'").join(', ');
      return '($values)';
    }).join(', ');
    final sql = 'INSERT INTO "${escapeName(query.tableName)}" ($fields) VALUES $values';
    return '$sql$terminator';
  }

  @override
  String acceptForeignKey(TableBlueprint blueprint, ForeignKey key) {
    blueprint.ensurePresenceOf(key.column);
    final sb = StringBuffer();

    final constraint = key.constraint;
    if (constraint != null) sb.write('CONSTRAINT $constraint ');

    sb.write(
        'FOREIGN KEY ("${escapeName(key.column)}") REFERENCES "${escapeName(key.foreignTable)}"("${escapeName(key.foreignTableColumn)}")');

    if (key.onUpdate != null) {
      sb.write(' ON UPDATE ${_acceptForeignKeyAction(key.onUpdate!)}');
    }
    if (key.onDelete != null) {
      sb.write(' ON DELETE ${_acceptForeignKeyAction(key.onDelete!)}');
    }
    return sb.toString();
  }

  String _acceptForeignKeyAction(ForeignKeyAction action) {
    return switch (action) {
      ForeignKeyAction.cascade => 'CASCADE',
      ForeignKeyAction.restrict => 'RESTRICT',
      ForeignKeyAction.setNull => 'SET NULL',
      ForeignKeyAction.setDefault => 'SET DEFAULT',
      ForeignKeyAction.noAction => 'NO ACTION',
    };
  }

  @override
  String acceptWhereClauseValue(WhereClauseValue clauseVal) {
    final field = '"${escapeName(clauseVal.field)}"';
    final value = clauseVal.comparer.value;
    final valueOperator = clauseVal.comparer.operator;
    final wrapped = acceptPrimitiveValue(value);

    return switch (valueOperator) {
      Operator.LESS_THAN => '$field < $wrapped',
      Operator.GREAT_THAN => '$field > $wrapped',
      Operator.LESS_THEN_OR_EQUAL_TO => '$field <= $wrapped',
      Operator.GREATER_THAN_OR_EQUAL_TO => '$field >= $wrapped',
      //
      Operator.EQUAL => '$field = $wrapped',
      Operator.NOT_EQUAL => '$field != $wrapped',
      //
      Operator.IN => '$field IN $wrapped',
      Operator.NOT_IN => '$field NOT IN $wrapped',
      //
      Operator.LIKE => '$field LIKE $wrapped',
      Operator.NOT_LIKE => '$field NOT LIKE $wrapped',
      //
      Operator.NULL => '$field IS NULL',
      Operator.NOT_NULL => '$field IS NOT NULL',
      //
      Operator.BETWEEN => '$field BETWEEN ${acceptPrimitiveValue(value[0])} AND ${acceptPrimitiveValue(value[1])}',
      Operator.NOT_BETWEEN =>
        '$field NOT BETWEEN ${acceptPrimitiveValue(value[0])} AND ${acceptPrimitiveValue(value[1])}',
    };
  }
}

@protected
class PgSqlTableBlueprint extends TableBlueprint {
  final List<String> statements = [];
  final List<String> _foreignKeys = [];

  String _getColumn(String name, String type, {nullable = false, defaultValue}) {
    final sb = StringBuffer()..write('"${escapeName(name)}" $type');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    return sb.toString();
  }

  @override
  void datetime(String name, {bool nullable = false, DateTime? defaultValue}) {
    statements.add(_getColumn(name, 'TIMESTAMP', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void blob(String name, {bool nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'BYTEA', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void boolean(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'BOOLEAN', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void id({name = 'id', String? type, autoIncrement = true}) {
    type ??= 'SERIAL';
    final sb = StringBuffer()..write('"${escapeName(name)}"');
    sb.write(autoIncrement ? " SERIAL PRIMARY KEY" : " $type PRIMARY KEY");
    statements.add(sb.toString());
  }

  @override
  String renameScript(String fromName, String toName) {
    return 'ALTER TABLE "${escapeName(fromName)}" RENAME TO "${escapeName(toName)}";';
  }

  @override
  void float(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    statements.add(_getColumn(name, 'DOUBLE PRECISION', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void double(String name, {bool nullable = false, num? defaultValue, int? precision = 10, int? scale = 0}) {
    statements.add(_getColumn(name, 'NUMERIC($precision, $scale)', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void tinyInt(String name, {bool nullable = false, num? defaultValue}) {
    throw UnimplementedError('tinyInt not implemented for Postgres');
  }

  @override
  void mediumInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void text(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int length = 1}) {
    statements.add(_getColumn(name, 'TEXT', nullable: nullable, defaultValue: null));
  }

  @override
  void longText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('longText not implemented for Postgres');
  }

  @override
  void mediumText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('mediumText not implemented for Postgres');
  }

  @override
  void tinyText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('tinyText not implemented for Postgres');
  }

  @override
  void binary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int size = 1}) {
    statements.add(_getColumn(name, 'BYTEA', nullable: nullable, defaultValue: null));
  }

  @override
  void varbinary(String name,
      {bool nullable = false, String? defaultValue, String? charset, String? collate, int size = 1}) {
    final type = 'BIT VARYING($size)';
    statements.add(_getColumn(name, type, nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void enums(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    final sb = StringBuffer()
      ..write('CREATE TYPE "${escapeName(name)}" AS ENUM (${values.map((e) => "'$e'").join(', ')});');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    statements.add(sb.toString());
  }

  @override
  void set(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    throw UnimplementedError('set not implemented for Postgres');
  }

  @override
  void bigInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'BIGINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void bit(String name, {bool nullable = false, int? defaultValue}) {
    statements.add(_getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void char(String name,
      {bool nullable = false, int length = 1, String? defaultValue, String? charset, String? collate}) {
    statements.add(_getColumn(name, 'CHAR($length)', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  String createScript(String tableName) {
    statements.addAll(_foreignKeys);
    return '''CREATE TABLE "${escapeName(tableName)}" (${statements.join(', ')});''';
  }

  @override
  void date(String name, {bool nullable = false, DateTime? defaultValue}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void decimal(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    statements.add(_getColumn(name, 'DECIMAL($precision, $scale)', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  String dropScript(String tableName) {
    return 'DROP TABLE IF EXISTS "${escapeName(tableName)}";';
  }

  @override
  String ensurePresenceOf(String column) {
    final exactLine = statements.firstWhereOrNull((e) => e.startsWith('"$column" '));
    if (exactLine == null) throw Exception('Column $column not found in table blueprint');
    return exactLine.split(' ')[1];
  }

  @override
  void integer(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void numeric(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    integer(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void smallInteger(String name, {bool nullable = false, num? defaultValue}) {
    integer(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void string(String name, {bool nullable = false, String? defaultValue}) {
    statements.add(_getColumn(name, 'VARCHAR', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void time(String name, {bool nullable = false, DateTime? defaultValue}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void timestamp(String name, {bool nullable = false, DateTime? defaultValue}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void timestamps({String createdAt = entityCreatedAtColumnName, String updatedAt = entityUpdatedAtColumnName}) {
    timestamp(createdAt);
    timestamp(updatedAt);
  }

  @override
  void varchar(String name,
      {bool nullable = false, String? defaultValue, int length = 255, String? charset, String? collate}) {
    string(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void foreign<Model extends Entity, ReferenceModel extends Entity>({
    String? column,
    ForeignKey Function(ForeignKey fkey)? onKey,
  }) {
    late ForeignKey result;
    callback(ForeignKey fkey) => result = onKey?.call(fkey) ?? fkey;

    super.foreign<Model, ReferenceModel>(column: column, onKey: callback);
    final statement = _primitiveSerializer.acceptForeignKey(this, result);
    _foreignKeys.add(statement);
  }
}
