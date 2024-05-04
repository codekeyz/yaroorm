part of 'entity.dart';

abstract class JoinBuilder<Owner extends Entity<Owner>> {}

class Join<Parent extends Entity<Parent>, Reference extends Entity<Reference>,
    Relationship extends EntityRelation<Parent, Reference>> {
  String get fromTable => Query.getEntity<Parent>().tableName;
  String get onTable => Query.getEntity<Reference>().tableName;

  final Entry<Parent> origin;
  final Entry<Reference> on;

  final String resultKey;

  /// This is the key that will be used to store the result of this
  /// of this relation in [Entity] relations cache.
  final String key;

  Iterable<String> get aliasedForeignSelections =>
      Query.getEntity<Reference>().columns.map((e) => '$onTable.${e.columnName} as "$resultKey.${e.columnName}"');

  Join(
    this.resultKey, {
    required this.origin,
    required this.on,
  }) : key = '$Relationship#$resultKey';
}

typedef Entry<T extends Entity<T>> = (Symbol symbol, String columnName);
