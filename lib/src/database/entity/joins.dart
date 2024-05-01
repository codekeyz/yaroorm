part of 'entity.dart';

abstract class JoinBuilder<Owner extends Entity<Owner>> {}

class Join<Parent extends Entity<Parent>, Reference extends Entity<Reference>,
    Relationship extends EntityRelation<Parent, Reference>> {
  String get fromTable => Query.getEntity<Parent>().tableName;
  String get onTable => Query.getEntity<Reference>().tableName;

  final Type relation;

  final Entry<Parent> origin;
  final Entry<Reference> on;

  final String resultKey;

  Iterable<String> get aliasedForeignSelections =>
      Query.getEntity<Reference>().columns.map((e) => '$onTable.${e.columnName} as "$resultKey.${e.columnName}"');

  Join(
    this.resultKey, {
    required this.origin,
    required this.on,
  }) : relation = Relationship;
}

typedef Entry<T extends Entity<T>> = (Symbol symbol, String columnName);
