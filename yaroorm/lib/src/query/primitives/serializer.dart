import '../query.dart';

abstract class PrimitiveSerializer {
  String acceptReadQuery(Query query);

  String acceptUpdateQuery(UpdateQuery query);

  String acceptDeleteQuery(DeleteQuery query);

  String acceptInsertQuery(InsertQuery query);

  String acceptInsertAllQuery(InsertManyQuery query);

  String acceptWhereClause(WhereClause clause);

  String acceptSelect(List<String> fields);

  String acceptOrderBy(List<OrderBy> orderBys);

  String acceptLimit(int limit);

  dynamic acceptDartValue(dynamic value);

  String get terminator;
}
