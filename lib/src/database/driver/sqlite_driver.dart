import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sql.dart';

import '../../migration.dart';
import '../../primitives/serializer.dart';
import '../../query/aggregates.dart';
import '../../query/query.dart';
import '../entity/entity.dart';
import '../entity/misc.dart';
import 'driver.dart';

final _serializer = const SqliteSerializer();

const _sqliteTypeConverters = <EntityTypeConverter>[
  booleanConverter,
  dateTimeConverter,
  ...defaultListConverters,
];

final class SqliteDriver implements DatabaseDriver {
  final DatabaseConnection config;

  Database? _database;

  SqliteDriver(this.config);

  @override
  Future<DatabaseDriver> connect({
    int? maxConnections,
    bool? singleConnection,
  }) async {
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
  Future<List<Map<String, dynamic>>> query(ReadQuery query) async {
    final sql = _serializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<int> update(UpdateQuery query) async {
    final sql = _serializer.acceptUpdateQuery(query);
    return (await _getDatabase()).rawUpdate(sql, query.data.values.toList());
  }

  @override
  Future<int> insert(InsertQuery query) async {
    final sql = _serializer.acceptInsertQuery(query);
    return (await _getDatabase()).rawInsert(sql, query.data.values.toList());
  }

  @override
  Future<void> insertMany(InsertManyQuery query) async {
    return await (await _getDatabase()).transaction((txn) => _SqliteTransactor(txn).insertMany(query));
  }

  @override
  Future<List<Map<String, dynamic>>> delete(DeleteQuery query) async {
    final sql = _serializer.acceptDeleteQuery(query);
    return (await _getDatabase()).rawQuery(sql);
  }

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  TableBlueprint get blueprint => SqliteTableBlueprint();

  @override
  List<EntityTypeConverter> get typeconverters => _sqliteTypeConverters;

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

  _SqliteTransactor(this._txn);

  @override
  Future<void> execute(String script) => _txn.execute(script);

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String script) => _txn.rawQuery(script);

  @override
  Future<List<Map<String, dynamic>>> query(ReadQuery query) async {
    final sql = _serializer.acceptReadQuery(query);
    return rawQuery(sql);
  }

  @override
  Future<void> delete(DeleteQuery query) {
    final sql = _serializer.acceptDeleteQuery(query);
    return _txn.rawDelete(sql);
  }

  @override
  Future<int> insert(InsertQuery query) {
    final sql = _serializer.acceptInsertQuery(query);
    return _txn.rawInsert(sql, query.data.values.toList());
  }

  @override
  Future<void> update(UpdateQuery query) {
    final sql = _serializer.acceptUpdateQuery(query);
    return _txn.rawUpdate(sql, query.data.values.toList());
  }

  @override
  Future<void> insertMany(InsertManyQuery query) async {
    final batch = _txn.batch();

    for (final entry in query.values) {
      final sql = _serializer.acceptInsertQuery(InsertQuery(
        query.$query,
        data: entry,
        primaryKey: query.primaryKey,
      ));
      batch.rawInsert(sql, entry.values.toList());
    }

    /// TODO(codekeyz): this returns entry IDS. verify the behavior when we have STRING IDs
    await batch.commit(noResult: false, continueOnError: false);
  }

  @override
  PrimitiveSerializer get serializer => _serializer;

  @override
  List<EntityTypeConverter> get typeconverters => _sqliteTypeConverters;

  @override
  DatabaseDriverType get type => DatabaseDriverType.sqlite;
}

class SqliteSerializer extends PrimitiveSerializer {
  const SqliteSerializer();

  @override
  String acceptAggregate(AggregateFunction aggregate) {
    final queryBuilder = StringBuffer();

    final selection = '${aggregate.name}(${aggregate.arguments.join(', ')})';
    queryBuilder.write('SELECT $selection FROM ${escapeStr(aggregate.tableName)}');

    /// WHERE
    final clause = aggregate.whereClause;
    if (clause != null) {
      queryBuilder.write(' WHERE ${acceptWhereClause(clause)}');
    }

    return '${queryBuilder.toString()}$terminator';
  }

  @override
  String acceptReadQuery(ReadQuery query) {
    final queryBuilder = StringBuffer();

    /// SELECT
    final tableName = escapeStr(query.tableName);
    final selectStatement = acceptSelect(tableName, query.fieldSelections.toList());
    queryBuilder.write(selectStatement);

    /// JOINS
    if (query.joins.isNotEmpty) {
      final selections = query.joins.map((e) => e.aliasedForeignSelections.join(', ')).join(', ');
      queryBuilder.write(', $selections FROM $tableName');

      for (final join in query.joins) {
        final field = '${escapeStr(join.origin.table)}.${escapeStr(join.origin.column)}';
        final referencedField = '${escapeStr(join.on.table)}.${escapeName(join.on.column)}';
        queryBuilder.writeln(' LEFT JOIN ${escapeName(join.on.table)} ON $field = $referencedField');
      }
    } else {
      queryBuilder.write(' FROM $tableName');
    }

    /// WHERE
    final whereClause = query.whereClause;
    if (whereClause != null) {
      queryBuilder.write(' WHERE ${acceptWhereClause(whereClause)}');
    }

    /// GROUP BY
    // if (query.groupBys.isNotEmpty) {
    //   queryBuilder.write(' GROUP BY ${query.groupBys.map((e) => '$tableName.$e')}');
    // }

    /// ORDER BY
    final orderBys = query.orderByProps ?? {};
    if (orderBys.isNotEmpty) {
      queryBuilder.write(' ORDER BY ${acceptOrderBy(orderBys.toList())}');
    }

    /// LIMIT
    final limit = query.limit;
    if (limit != null) {
      queryBuilder.write(' LIMIT ${acceptLimit(limit)}');
    }

    /// OFFSET
    final offset = query.offset;
    if (offset != null) {
      queryBuilder.write(' OFFSET ${acceptOffset(offset)}');
    }

    return '${queryBuilder.toString()}$terminator';
  }

  String acceptWhereClause(WhereClause clause) {
    if (clause is WhereClauseValue) {
      return acceptWhereClauseValue(clause);
    }

    final whereStr = StringBuffer();

    if (clause.values.isNotEmpty) {
      final combiner = clause is $AndGroup ? 'AND' : 'OR';

      final children = clause.values;
      final group = StringBuffer();

      for (final val in children) {
        final res = acceptWhereClause(val);
        if (res.isNotEmpty) {
          group.write(group.isEmpty ? res : ' $combiner $res');
        }
      }

      final result = children.length > 1 ? '(${group.toString()})' : group.toString();

      if (whereStr.isNotEmpty) {
        whereStr.write('$combiner $result');
      } else {
        whereStr.write(result);
      }
    }

    return whereStr.toString();
  }

  @override
  String acceptUpdateQuery(UpdateQuery query) {
    final queryBuilder = StringBuffer();

    final fields = query.data.keys.map((e) => '${escapeStr(e)} = ?').join(', ');

    queryBuilder.write('UPDATE ${escapeStr(query.tableName)}');

    queryBuilder
      ..write(' SET $fields')
      ..write(' WHERE ${acceptWhereClause(query.whereClause)}')
      ..write(terminator);

    return queryBuilder.toString();
  }

  @override
  String acceptInsertQuery(InsertQuery query) {
    final fields = query.data.keys.map(escapeStr);
    final params = List<String>.filled(fields.length, '?').join(', ');
    return 'INSERT INTO ${escapeStr(query.tableName)} (${fields.join(', ')}) VALUES ($params)$terminator';
  }

  @override
  String acceptInsertManyQuery(InsertManyQuery query) {
    final fields = query.values.first.keys.map(escapeStr);
    final params = List<String>.filled(fields.length, '?').join(', ');
    return 'INSERT INTO ${escapeStr(query.tableName)} (${fields.join(', ')}) VALUES ($params)$terminator';
  }

  @override
  String acceptDeleteQuery(DeleteQuery query) {
    final queryBuilder = StringBuffer();

    queryBuilder
      ..write('DELETE FROM ${escapeStr(query.tableName)}')
      ..write(' WHERE ${acceptWhereClause(query.whereClause)}')
      ..write(terminator);

    return queryBuilder.toString();
  }

  @override
  String acceptSelect(String tableName, List<String> fields) {
    return fields.isEmpty
        ? 'SELECT $tableName.*'
        : 'SELECT ${fields.map((e) => '$tableName.${escapeStr(e)}').join(', ')}';
  }

  @override
  String acceptOrderBy(List<OrderBy> orderBys) {
    direction(OrderDirection dir) => dir == OrderDirection.asc ? 'ASC' : 'DESC';
    return orderBys.map((e) => '${e.field} ${direction(e.direction)}').join(', ');
  }

  @override
  String acceptLimit(int limit) => '$limit';

  @override
  String acceptOffset(int offset) => '$offset';

  @override
  String get terminator => ';';

  @override
  dynamic acceptPrimitiveValue(value) => switch (value.runtimeType) {
        const (int) || const (double) || const (num) => value,
        const (List<String>) => '(${value.map((e) => "'$e'").join(', ')})',
        const (List<int>) || const (List<num>) || const (List<double>) => '(${value.join(', ')})',
        _ => "'$value'"
      };

  @override
  String acceptWhereClauseValue(WhereClauseValue clauseValue) {
    final tableName = clauseValue.table;
    final field = tableName == null ? escapeStr(clauseValue.field) : '$tableName.${escapeStr(clauseValue.field)}';

    final valueOperator = clauseValue.operator;

    /// For this operators, Ignore the conversion of value to DB Type.
    const operatorsToIgnore = [Operator.BETWEEN, Operator.NOT_BETWEEN];
    final value = !operatorsToIgnore.contains(valueOperator) ? clauseValue.dbValue : clauseValue.value;
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
  String acceptForeignKey(TableBlueprint blueprint, ForeignKey key) {
    blueprint.ensurePresenceOf(escapeStr(key.column));
    final sb = StringBuffer();

    final constraint = key.constraint;
    if (constraint != null) sb.write('CONSTRAINT $constraint ');

    sb.write(
        'FOREIGN KEY (${escapeStr(key.column)}) REFERENCES ${escapeStr(key.foreignTable)}(${escapeStr(key.foreignTableColumn)})');

    if (key.onUpdate != null) {
      sb.write(' ON UPDATE ${_acceptForeignKeyAction(key.onUpdate!)}');
    }
    if (key.onDelete != null) {
      sb.write(' ON DELETE ${_acceptForeignKeyAction(key.onDelete!)}');
    }

    return sb.toString();
  }

  @override
  String escapeStr(String column) => escapeName(column);
}

@protected
class SqliteTableBlueprint extends TableBlueprint {
  final List<String> statements = [];
  final List<String> _foreignKeys = [];

  PrimitiveSerializer get szler => _serializer;

  String makeColumn(String name, String type, {nullable = false, defaultValue, bool unique = false}) {
    final sb = StringBuffer()..write('${szler.escapeStr(name)} $type');
    if (unique) sb.write(' UNIQUE');

    if (!nullable) {
      sb.write(' NOT NULL');
      if (defaultValue != null) {
        final value = szler.acceptPrimitiveValue(defaultValue);
        sb.write(' DEFAULT $value');
      }
    }
    return sb.toString();
  }

  @override
  void id({name = 'id', String? type, autoIncrement = true}) {
    type ??= 'INTEGER';

    final sb = StringBuffer()..write('${szler.escapeStr(name)} $type NOT NULL PRIMARY KEY');
    if (autoIncrement) sb.write(' AUTOINCREMENT');
    statements.add(sb.toString());
  }

  @override
  void string(String name, {nullable = false, defaultValue, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'VARCHAR',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void double(String name, {nullable = false, defaultValue, int? precision, int? scale, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'REAL',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void float(String name, {nullable = false, defaultValue, int? precision, int? scale, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'REAL',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void integer(String name, {nullable = false, defaultValue, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'INTEGER',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void blob(String name, {nullable = false, defaultValue}) {
    statements.add(makeColumn(name, 'BLOB', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void boolean(String name, {nullable = false, defaultValue}) {
    statements.add(makeColumn(name, 'INTEGER', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void datetime(String name, {nullable = false, defaultValue, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'DATETIME',
      nullable: nullable,
      defaultValue: defaultValue?.toIso8601String(),
      unique: unique,
    ));
  }

  @override
  void timestamp(String name, {nullable = false, defaultValue, bool unique = false}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void date(String name, {bool nullable = false, DateTime? defaultValue, bool unique = false}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void time(String name, {bool nullable = false, DateTime? defaultValue, bool unique = false}) {
    datetime(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void timestamps({
    String createdAt = 'createdAt',
    String updatedAt = 'updatedAt',
  }) {
    timestamp(createdAt);
    timestamp(updatedAt);
  }

  @override
  void bigInteger(String name, {bool nullable = false, num? defaultValue, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'BIGINT',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void binary(String name,
      {bool nullable = false, int size = 1, String? defaultValue, String? charset, String? collate}) {
    statements.add(makeColumn(name, 'BLOB', nullable: nullable, defaultValue: defaultValue));
  }

  @override
  void bit(String name, {bool nullable = false, int? defaultValue, bool unique = false}) {
    statements.add(makeColumn(
      name,
      'INTEGER',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void char(
    String name, {
    bool nullable = false,
    int length = 1,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    statements.add(makeColumn(
      name,
      'CHAR($length)',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void decimal(
    String name, {
    bool nullable = false,
    num? defaultValue,
    int? precision,
    int? scale,
    bool unique = false,
  }) {
    statements.add(makeColumn(
      name,
      'DECIMAL($precision, $scale)',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void enums(
    String name,
    List<String> values, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    statements.add(makeColumn(
      name,
      'TEXT CHECK ($name IN (${values.map((e) => "'$e'").join(', ')}))',
      nullable: nullable,
      defaultValue: defaultValue,
      unique: unique,
    ));
  }

  @override
  void mediumText(
    String name, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    string(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void longText(
    String name, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    string(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void mediumInteger(String name, {bool nullable = false, num? defaultValue, bool unique = false}) {
    integer(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void numeric(
    String name, {
    bool nullable = false,
    num? defaultValue,
    int? precision,
    int? scale,
    bool unique = false,
  }) {
    integer(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void set(
    String name,
    List<String> values, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    throw UnimplementedError();
  }

  @override
  void smallInteger(String name, {bool nullable = false, num? defaultValue, bool unique = false}) {
    integer(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void text(
    String name, {
    int length = 1,
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    string(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void tinyInt(String name, {bool nullable = false, num? defaultValue, bool unique = false}) {
    integer(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void tinyText(
    String name, {
    bool nullable = false,
    String? defaultValue,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    string(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  void varbinary(
    String name, {
    bool nullable = false,
    int size = 1,
    String? defaultValue,
    String? charset,
    String? collate,
  }) {
    binary(name, nullable: nullable, defaultValue: defaultValue);
  }

  @override
  void varchar(
    String name, {
    bool nullable = false,
    String? defaultValue,
    int length = 255,
    String? charset,
    String? collate,
    bool unique = false,
  }) {
    string(name, nullable: nullable, defaultValue: defaultValue, unique: unique);
  }

  @override
  String createScript(String tableName) {
    statements.addAll(_foreignKeys);
    return 'CREATE TABLE ${szler.escapeStr(tableName)} (${statements.join(', ')});';
  }

  @override
  String dropScript(String tableName) {
    return 'DROP TABLE IF EXISTS ${szler.escapeStr(tableName)};';
  }

  @override
  String renameScript(String fromName, String toName) {
    final StringBuffer renameScript = StringBuffer();
    renameScript
      ..writeln('CREATE TABLE temp_info AS SELECT * FROM PRAGMA table_info(\'$fromName\');')
      ..writeln('CREATE TABLE temp_data AS SELECT * FROM $fromName;')
      ..writeln('CREATE TABLE $toName AS SELECT * FROM temp_data WHERE 1 = 0;')
      ..writeln('INSERT INTO $toName SELECT * FROM temp_data;')
      ..writeln('DROP TABLE temp_info; DROP TABLE temp_data;');
    return renameScript.toString();
  }

  @override
  String ensurePresenceOf(String column) {
    final exactLine = statements.firstWhereOrNull((e) => e.startsWith('$column '));
    if (exactLine == null) {
      throw Exception('Column $column not found in table blueprint');
    }
    return exactLine.split(' ')[1];
  }

  @override
  void foreign(ForeignKey key) {
    _foreignKeys.add(szler.acceptForeignKey(this, key));
  }
}
