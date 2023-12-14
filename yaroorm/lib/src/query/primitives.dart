import '../database/driver/driver.dart';
import 'query.dart';

typedef WhereData<A> = ({String field, Symbol optor, A? value});

class WhereCondition {
  final WhereData<dynamic> value;
  const WhereCondition(this.value);
}

enum OrderByDirection { asc, desc }

typedef OrderBy = ({String field, OrderByDirection order});

abstract interface class TableOperations<Model extends Entity> {
  RecordQueryInterface<Model> where<Value>(String field, Symbol optor, Value value);

  RecordQueryInterface<Model> select(List<String> fields);

  RecordQueryInterface<Model> orderBy(String field, OrderByDirection direction);

  Future<Model> get({DatabaseDriver? driver});
}

abstract class QueryPrimitiveSerializer {
  String acceptWhereCondition(WhereCondition condition);

  String acceptSelect(List<String> fields);
}
