part of 'entity.dart';

abstract class JoinBuilder<Owner extends Entity<Owner>> {}

class Join<From extends Entity<From>, On extends Entity<On>> {
  final _Element<From> origin;
  final _Element<On> destination;

  Join(Symbol origin, {required Symbol on})
      : origin = _Element<From>(origin),
        destination = _Element<On>(on);
}

final class _Element<T extends Entity<T>> {
  final Symbol symbol;

  DBEntity<T> get typeDef => Query.getEntity<T>();

  const _Element(this.symbol);
}
