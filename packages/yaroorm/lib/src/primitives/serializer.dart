import 'package:yaroorm/migration.dart';
import 'package:yaroorm/src/query/aggregates.dart';

import '../query/query.dart';
import 'where.dart';

abstract class PrimitiveSerializer {
  String acceptAggregate(AggregateFunction aggregate);

  String acceptReadQuery(Query query);

  String acceptUpdateQuery(UpdateQuery query);

  String acceptDeleteQuery(DeleteQuery query);

  String acceptInsertQuery(InsertQuery query);

  String acceptInsertManyQuery(InsertManyQuery query);

  String acceptWhereClause(WhereClause clause);

  String acceptWhereClauseValue(WhereClauseValue clauseValue);

  String acceptSelect(List<String> fields);

  String acceptOrderBy(List<OrderBy> orderBys);

  String acceptLimit(int limit);

  dynamic acceptPrimitiveValue(dynamic value);

  String acceptForeignKey(TableBlueprint blueprint, ForeignKey key);

  String escapeStr(String column);

  String acceptCountQuery(String table, String field);

  String acceptGroupConcatQuery(String table, String field);

  String acceptMaxQuery(String table, String field);

  String acceptMinQuery(String table, String field);

  String acceptSumQuery(String table, String field);

  String acceptTotalQuery(String table, String field);

  String acceptAverageQuery(String table, String field);

  String get terminator;
}
