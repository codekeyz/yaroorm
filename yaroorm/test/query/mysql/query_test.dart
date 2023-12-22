import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../helpers/drivers.dart';
import '../where_query_base.dart';

final _driver = DatabaseDriver.init(mysqlConnection);

void main() {
  group('Query.query', () {
    group('when `.orderByAsc`', () {
      test(' of level 1', () {
        expect(
          Query.query('users', _driver).orderByAsc('firstname').statement,
          'SELECT * FROM users ORDER BY firstname ASC;',
        );
      });

      test(' of level 2', () {
        expect(
          Query.query('users', _driver).orderByAsc('firstname').orderByAsc('lastname').statement,
          'SELECT * FROM users ORDER BY firstname ASC, lastname ASC;',
        );
      });

      test(' of level 3', () {
        expect(
          Query.query('users', _driver).orderByAsc('firstname').orderByDesc('lastname').orderByAsc('age').statement,
          'SELECT * FROM users ORDER BY firstname ASC, lastname DESC, age ASC;',
        );
      });
    });

    group('when `.orderByDesc`', () {
      test(' of level 1', () {
        expect(
          Query.query('users', _driver).orderByDesc('firstname').statement,
          'SELECT * FROM users ORDER BY firstname DESC;',
        );
      });

      test(' of level 2', () {
        expect(
          Query.query('users', _driver).orderByDesc('firstname').orderByDesc('lastname').statement,
          'SELECT * FROM users ORDER BY firstname DESC, lastname DESC;',
        );
      });

      test(' of level 3', () {
        expect(
          Query.query('users', _driver)
              .where('firstname', 'not null')
              .orderByDesc('lastname')
              .orderByDesc('age')
              .statement,
          'SELECT * FROM users WHERE firstname IS NOT NULL ORDER BY lastname DESC, age DESC;',
        );
      });
    });
  });

  group('Query.query with WHERE', () => whereTestGroup(_driver));
}
