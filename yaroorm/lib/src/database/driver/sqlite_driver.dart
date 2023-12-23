import 'package:meta/meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yaroorm/src/database/migration.dart';
import 'package:yaroorm/src/query/primitives/serializer.dart';
import 'package:yaroorm/src/query/query.dart';

import 'driver.dart';

final _serializer = const SqliteSerializer();

final _sqliteTableBlueprint = SqliteTableBlueprint();

@visibleForTesting
@protected
class SqliteDriver implements DatabaseDriver {
  final DatabaseConnection config;

  Database? _database;

  SqliteDriver(this.config);

  @override
  Future<DatabaseDriver> connect({int? maxConnections, bool? singleConnection}) async {
    assert(maxConnections == null, 'Sqlite does not support max connections');
    assert(singleConnection == null, 'Sqlite does not support single connection');

    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    _database = await databaseFactory.openDatabase(config.database, options: OpenDatabaseOptions(onOpen: (db) async {
      if (config.dbForeignKeys) {
        await db.execute('PRAGMA foreign_keys = ON;');
      }
    }));
    return this;
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
  DatabaseDriverType get type => DatabaseDriverType.sqlite;

  Future<Database> _getDatabase() async {
    if (!isOpen) await connect();
    return _database!;
  }

  @override
  Future<void> execute(String script) async {
    return (await _getDatabase()).execute(script);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) async {
    return (await _getDatabase()).rawQuery(script);
  }

  @override
  Future<List<Map<String, dynamic>>> query(Query query) async {
    final sql = _serializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> update(UpdateQuery query) async {
    final sql = _serializer.acceptUpdateQuery(query);
    return (await _getDatabase()).rawQuery(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) async {
    final sql = _serializer.acceptDeleteQuery(query);
    return (await _getDatabase()).rawQuery(sql);
  }

  @override
  Future<int> insert(InsertQuery query) async {
    return (await _getDatabase()).insert(query.tableName, query.values);
  }

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  TableBlueprint get blueprint => _sqliteTableBlueprint;

  @override
  Future<bool> hasTable(String tableName) async {
    final result = await (await _getDatabase()).rawQuery(
        'SELECT 1 FROM sqlite_master WHERE type = ${wrapString('table')} AND name = ${wrapString(tableName)} LIMIT 1;');
    return result.isNotEmpty;
  }

  @override
  Future<void> transaction(Function(DriverTransactor transactor) func) async {
    return (await _getDatabase()).transaction((txn) => func(_SqliteTransactor(txn)));
  }
}

class _SqliteTransactor implements DriverTransactor {
  final Transaction _txn;
  final Batch _batch;

  _SqliteTransactor(this._txn) : _batch = _txn.batch();

  @override
  Future<void> execute(String script) => _txn.execute(script);

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) => _txn.rawQuery(script);

  @override
  Future<List<Map<String, dynamic>>> query(Query query) async {
    final sql = _serializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<void> update(UpdateQuery query) {
    final sql = _serializer.acceptUpdateQuery(query);
    return Future.sync(() => _batch.rawUpdate(sql));
  }

  @override
  Future<void> delete(DeleteQuery query) {
    final sql = _serializer.acceptDeleteQuery(query);
    return Future.sync(() => _batch.rawDelete(sql));
  }

  @override
  Future<void> insert(InsertQuery query) {
    return Future.sync(() => _batch.insert(query.tableName, query.values));
  }

  @override
  Future<List<Object?>> commit() => _batch.commit();

  @override
  PrimitiveSerializer get serializer => _serializer;
}

@protected
class SqliteSerializer implements PrimitiveSerializer {
  const SqliteSerializer();

  @override
  String acceptReadQuery(Query query) {
    final queryBuilder = StringBuffer();

    /// SELECT
    final selectStatement = acceptSelect(query.fieldSelections.toList());
    queryBuilder.write(selectStatement);
    queryBuilder.write('FROM ${query.tableName}');

    /// WHERE
    final clauses = query.whereClauses;
    if (clauses.isNotEmpty) {
      final sb = StringBuffer();

      final differentOperators = clauses.map((e) => e.operator).toSet().length > 1;

      for (final clause in clauses) {
        final result = acceptWhereClause(clause, canGroup: differentOperators);
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
  String acceptUpdateQuery(UpdateQuery query) {
    final queryBuilder = StringBuffer();

    queryBuilder.write('UPDATE ${query.tableName}');

    final values = query.values.entries.map((e) => '${e.key} = ${acceptDartValue(e.value)}').join(', ');

    queryBuilder
      ..write(' SET $values')
      ..write(' WHERE ${acceptWhereClause(query.whereClause)}')
      ..write(terminator);

    return queryBuilder.toString();
  }

  @override
  String acceptInsertQuery(InsertQuery query) {
    final data = query.values;
    final fields = data.keys.join(', ');
    final values = data.values.map((e) => acceptDartValue(e)).join(', ');
    return 'INSERT INTO ${query.tableName} ($fields) VALUES ($values)$terminator';
  }

  @override
  String acceptInsertAllQuery(InsertManyQuery query) {
    final data = query.values;
    final fields = data.first.keys.join(', ');
    final values = data.map((e) => '(${e.values.map((e) => acceptDartValue(e)).join(', ')})').join(', ');
    return 'INSERT INTO ${query.tableName} ($fields) VALUES $values$terminator';
  }

  @override
  String acceptDeleteQuery(DeleteQuery query) {
    final queryBuilder = StringBuffer();

    queryBuilder
      ..write('DELETE FROM ${query.tableName}')
      ..write(' WHERE ${acceptWhereClause(query.whereClause)}')
      ..write(terminator);

    return queryBuilder.toString();
  }

  @override
  String acceptSelect(List<String> fields) {
    return fields.isEmpty ? 'SELECT * ' : 'SELECT ${fields.join(', ')}';
  }

  @override
  String acceptWhereClause(WhereClause clause, {bool canGroup = false}) {
    if (clause is! WhereClauseImpl) {
      return _acceptWhereClauseValue(clause.clauseValue!);
    }

    final value = clause.clauseValue;
    final subParts = <(LogicalOperator operator, WhereClauseValue value)>[
      if (value != null) (clause.operator, value),
      ...clause.subparts.map((e) => (e.$1, e.$2)).toList(),
    ];

    /// If there are different logical operators joining the WhereGroups and a particular
    /// group has more than one subpart, then we should wrap it in (...)
    canGroup = canGroup && subParts.length > 1;

    final result = processClause(subParts);

    return !canGroup ? result : '($result)';
  }

  @override
  String acceptOrderBy(List<OrderBy> orderBys) {
    direction(OrderByDirection dir) => dir == OrderByDirection.asc ? 'ASC' : 'DESC';
    return orderBys.map((e) => '${e.field} ${direction(e.direction)}').join(', ');
  }

  @override
  String acceptLimit(int limit) => '$limit';

  @override
  String get terminator => ';';

  @override
  dynamic acceptDartValue(dartValue) => switch (dartValue.runtimeType) {
        const (int) || const (double) => dartValue,
        const (List<String>) => '(${dartValue.map((e) => "'$e'").join(', ')})',
        const (List<int>) || const (List<num>) || const (List<double>) => '(${dartValue.join(', ')})',
        _ => "'$dartValue'"
      };

  String _acceptWhereClauseValue(WhereClauseValue clauseVal) {
    final field = clauseVal.field;
    final value = clauseVal.comparer.value;
    final valueOperator = clauseVal.comparer.operator;
    final wrapped = acceptDartValue(value);

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
      Operator.BETWEEN => '$field BETWEEN ${acceptDartValue(value[0])} AND ${acceptDartValue(value[1])}',
      Operator.NOT_BETWEEN => '$field NOT BETWEEN ${acceptDartValue(value[0])} AND ${acceptDartValue(value[1])}',
    };
  }

  String processClause(List<(LogicalOperator operator, WhereClauseValue value)> subParts) {
    final group = StringBuffer();

    final firstPart = subParts.removeAt(0);
    group.write(_acceptWhereClauseValue(firstPart.$2));

    if (subParts.isNotEmpty) {
      for (final part in subParts) {
        final value = part.$2;
        group.write(' ${part.$1.name} ${_acceptWhereClauseValue(value)}');
      }
    }

    return group.toString();
  }
}

@protected
class SqliteTableBlueprint implements TableBlueprint {
  final List<String> statements = [];

  String _getColumn(String name, String type, {nullable = false, defaultValue}) {
    final sb = StringBuffer()..write('$name $type');
    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) sb.write(' DEFAULT $defaultValue');
    }
    return sb.toString();
  }

  @override
  void id({name = 'id', autoIncrement = true}) {
    final sb = StringBuffer()..write('$name INTEGER NOT NULL PRIMARY KEY');
    if (autoIncrement) sb.write(' AUTOINCREMENT');
    statements.add(sb.toString());
  }

  @override
  void string(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(
      name,
      'VARCHAR',
      nullable: nullable,
      defaultValue: defaultValue,
    ));
  }

  @override
  void double(String name, {nullable = false, defaultValue, int? precision, int? scale}) {
    statements.add(_getColumn(name, 'REAL', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void float(String name, {nullable = false, defaultValue, int? precision, int? scale}) {
    statements.add(_getColumn(name, 'REAL', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void integer(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void blob(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'BLOB', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void boolean(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void datetime(String name, {nullable = false, defaultValue}) {
    statements.add(_getColumn(name, 'DATETIME', nullable: nullable, defaultValue: defaultValue?.toIso8601String()));
  }

  @override
  void timestamp(String name, {nullable = false, defaultValue}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void date(String name, {bool nullable = false, DateTime? defaultValue}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void time(String name, {bool nullable = false, DateTime? defaultValue}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void timestamps({
    String createdAt = 'created_at',
    String updatedAt = 'updated_at',
  }) {
    timestamp(createdAt);
    timestamp(updatedAt);
  }

  @override
  void bigInteger(String name, {bool nullable = false, num? defaultValue}) {
    statements.add(_getColumn(name, 'BIGINT', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void binary(String name,
      {bool nullable = false, int length = 1, String? defaultValue, String? charset, String? collate}) {
    statements.add(_getColumn(name, 'BLOB', nullable: nullable, defaultValue: defaultValue));
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
  void decimal(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    statements.add(_getColumn(name, 'DECIMAL($precision, $scale)', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void enums(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    statements.add(_getColumn(name, 'TEXT CHECK ($name IN (${values.map((e) => "'$e'").join(', ')}))',
        nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void mediumText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    string(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void longText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    string(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void mediumInteger(String name, {bool nullable = false, num? defaultValue}) {
    integer(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void numeric(String name, {bool nullable = false, num? defaultValue, int? precision, int? scale}) {
    integer(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void set(String name, List<String> values,
      {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    // TODO: implement set
  }

  @override
  void smallInteger(String name, {bool nullable = false, num? defaultValue}) {
    integer(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void text(String name,
      {int length = 1, bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    string(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void tinyInt(String name, {bool nullable = false, num? defaultValue}) {
    integer(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void tinyText(String name, {bool nullable = false, String? defaultValue, String? charset, String? collate}) {
    string(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void varbinary(String name,
      {bool nullable = false, int length = 1, String? defaultValue, String? charset, String? collate}) {
    binary(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void varchar(String name,
      {bool nullable = false, String? defaultValue, int size = 255, String? charset, String? collate}) {
    string(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  String createScript(String tableName) {
    return 'CREATE TABLE $tableName (${statements.join(', ')});';
  }

  @override
  String dropScript(String tableName) {
    return 'DROP TABLE IF EXISTS $tableName;';
  }

  @override
  String renameScript(String oldName, String toName) {
    final StringBuffer renameScript = StringBuffer();
    renameScript
      ..writeln('CREATE TABLE temp_info AS SELECT * FROM PRAGMA table_info(\'$oldName\');')
      ..writeln('CREATE TABLE temp_data AS SELECT * FROM $oldName;')
      ..writeln('CREATE TABLE $toName AS SELECT * FROM temp_data WHERE 1 = 0;')
      ..writeln('INSERT INTO $toName SELECT * FROM temp_data;')
      ..writeln('DROP TABLE temp_info; DROP TABLE temp_data;');
    return renameScript.toString();
  }
}
