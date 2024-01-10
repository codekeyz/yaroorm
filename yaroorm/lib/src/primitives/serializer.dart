import 'package:yaroorm/migration.dart';

import '../query/query.dart';
import 'where.dart';

abstract class PrimitiveSerializer {
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

  Map<String, dynamic> conformToDBTypes(Map<String, dynamic> data);

  Map<String, dynamic> conformToEntity(Type type, Map<String, dynamic> dataFromDb);

  String acceptForeignKey(TableBlueprint blueprint, ForeignKey key);

  String get terminator;
}
