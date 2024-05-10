part of 'entity.dart';

abstract class JoinBuilder<Owner extends Entity<Owner>> {}

final class Join<Parent extends Entity<Parent>, Reference extends Entity<Reference>> {
  final Entry<Parent> origin;
  final Entry<Reference> on;

  final String resultKey;

  /// This is the key that will be used to store the result of this
  /// of this relation in [Entity] relations cache.
  final String key;

  Iterable<String> get aliasedForeignSelections =>
      Query.getEntity<Reference>().columns.map((e) => '${on.table}.${e.columnName} as "$resultKey.${e.columnName}"');

  const Join(
    this.resultKey, {
    required this.origin,
    required this.on,
    required Type key,
  }) : key = '$key#$resultKey';

  static String _getKey(Type type, String methodName) {
    return '$type#$methodName';
  }
}

typedef Entry<T extends Entity<T>> = ({String table, String column});
