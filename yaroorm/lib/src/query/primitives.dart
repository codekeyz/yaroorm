import 'engine.dart';
import 'model.dart';

mixin TableOperations<Model extends Entity> {
  RecordSelection<Model> where<Value>(String field, Symbol optor, Value value);

  RecordSelection<Model> select(List<String> fields);

  RecordSelection<Model> orderBy(String field, OrderByDirection direction);

  Future<Model> get();
}

typedef WhereData<A> = ({String field, Symbol optor, A? value});

class WhereCondition {
  final WhereData<dynamic> value;
  const WhereCondition(this.value);
}

enum OrderByDirection { asc, desc }

typedef OrderBy = ({String field, OrderByDirection order});
