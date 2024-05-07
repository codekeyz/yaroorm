part of 'entity.dart';

abstract class JoinBuilder<Owner extends Entity<Owner>> {}

class Join<Parent extends Entity<Parent>, Reference extends Entity<Reference>> {
  final Entry<Parent> origin;
  final Entry<Reference> on;

  final String resultKey;

  /// This is the key that will be used to store the result of this
  /// of this relation in [Entity] relations cache.
  final Type key;

  Iterable<String> get aliasedForeignSelections =>
      Query.getEntity<Reference>().columns.map((e) => '${on.table}.${e.columnName} as "$resultKey.${e.columnName}"');

  Join(
    this.resultKey, {
    required this.origin,
    required this.on,
    required this.key,
  });
}

typedef Entry<T extends Entity<T>> = ({String table, String column});
