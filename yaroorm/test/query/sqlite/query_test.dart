import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../helpers/drivers.dart';

void main() {
  late DatabaseDriver driver;

  setUpAll(() => driver = DatabaseDriver.init(sqliteConnection));

  group('Query.query', () {
    group('when `.orderByAsc`', () {
      test(' of level 1', () {
        expect(
          Query.query('users', driver).orderByAsc('firstname').statement,
          'SELECT * FROM users ORDER BY firstname ASC;',
        );
      });

      test(' of level 2', () {
        expect(
          Query.query('users', driver).orderByAsc('firstname').orderByAsc('lastname').statement,
          'SELECT * FROM users ORDER BY firstname ASC, lastname ASC;',
        );
      });

      test(' of level 3', () {
        expect(
          Query.query('users', driver).orderByAsc('firstname').orderByDesc('lastname').orderByAsc('age').statement,
          'SELECT * FROM users ORDER BY firstname ASC, lastname DESC, age ASC;',
        );
      });
    });

    group('when `.orderByDesc`', () {
      test(' of level 1', () {
        expect(
          Query.query('users', driver).orderByDesc('firstname').statement,
          'SELECT * FROM users ORDER BY firstname DESC;',
        );
      });

      test(' of level 2', () {
        expect(
          Query.query('users', driver).orderByDesc('firstname').orderByDesc('lastname').statement,
          'SELECT * FROM users ORDER BY firstname DESC, lastname DESC;',
        );
      });

      test(' of level 3', () {
        expect(
          Query.query('users', driver)
              .where('firstname', 'not null')
              .orderByDesc('lastname')
              .orderByDesc('age')
              .statement,
          'SELECT * FROM users WHERE firstname IS NOT NULL ORDER BY lastname DESC, age DESC;',
        );
      });
    });
  });
}
