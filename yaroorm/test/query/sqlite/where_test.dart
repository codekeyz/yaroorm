import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

void main() {
  late DatabaseDriver driver;

  setUpAll(() => driver = DatabaseDriver.init(DatabaseConnection(
        'testdb',
        'sqlite',
        DatabaseDriverType.sqlite,
      )));

  group('Query with', () {
    group('.where', () {
      test('of level 1', () {
        final query =
            Query.make('users', driver).where('firstname', '=', 'Chima');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname = \'Chima\';',
        );
      });

      test('of level 2', () {
        final query = Query.make('users', driver)
            .where('firstname', '=', 'Chima')
            .where('lastname', '=', 'Precious');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname = \'Precious\';',
        );
      });

      test('of level 3', () {
        final query = Query.make('users', driver)
            .where('firstname', '=', 'Chima')
            .where('lastname', '=', 'Precious')
            .where('age', '=', 22);

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname = \'Precious\' AND age = 22;',
        );
      });

      group('chained with `.orWhere`', () {
        test('of level 1', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203;',
          );
        });

        test('of level 2', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .where('city', '!=', 'Accra');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203 AND city != \'Accra\';',
          );
        });

        test('of level 3', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .orWhere('city', '!=', 'Accra');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203 OR city != \'Accra\';',
          );
        });

        test('of level 4', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .orWhere('city', '!=', 'Accra')
              .where('name', 'like', 'Chima%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203 OR city != \'Accra\' AND name LIKE \'Chima%\';',
          );
        });

        test('of level 4', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .orWhere('city', '!=', 'Accra')
              .where('name', 'like', 'Chima%')
              .where('sizes', 'between', [12, 23]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203 OR city != \'Accra\' AND name LIKE \'Chima%\' AND sizes BETWEEN 12 AND 23;',
          );
        });
      });

      group('chained with', () {
        test('.whereNull', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereNull('age');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age IS NULL;',
          );
        });

        test('.whereNotNull', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereNotNull('age');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age IS NOT NULL;',
          );
        });

        test('.whereIn', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereIn('age', [22, 24, 25]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age IN (22, 24, 25);',
          );
        });

        test('.whereNotIn', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereNotIn('age', [22, 24, 25]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age NOT IN (22, 24, 25);',
          );
        });

        test('.whereLike', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereLike('lastname', 'hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname LIKE \'hello%\';',
          );
        });

        test('.whereNotLike', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereNotLike('lastname', 'hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname NOT LIKE \'hello%\';',
          );
        });

        test('.whereBetween', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereBetween<int>('lastname', (22, 50));

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname BETWEEN 22 AND 50;',
          );
        });

        test('.whereNotBetween', () {
          final query = Query.make('users', driver)
              .where('firstname', '=', 'Chima')
              .whereNotBetween<double>('lastname', (22.34, 50));

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname NOT BETWEEN 22.34 AND 50.0;',
          );
        });
      });
    });

    group('handwritten operator', () {
      test('=', () {
        final query =
            Query.make('users', driver).where('firstname', '=', 'Chima');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname = \'Chima\';',
        );
      });

      test('!=', () {
        final query =
            Query.make('users', driver).where('firstname', '!=', 'Chima');

        expect(query.statement,
            'SELECT * FROM users WHERE firstname != \'Chima\';');
      });

      test('>', () {
        final query = Query.make('users', driver).where('age', '>', 23);

        expect(query.statement, 'SELECT * FROM users WHERE age > 23;');
      });

      test('<', () {
        final query = Query.make('users', driver).where('age', '<', 23);

        expect(query.statement, 'SELECT * FROM users WHERE age < 23;');
      });

      test('>=', () {
        final query = Query.make('users', driver).where('age', '>=', 223);

        expect(query.statement, 'SELECT * FROM users WHERE age >= 223;');
      });

      test('<=', () {
        final query = Query.make('users', driver).where('age', '<=', 34.3);

        expect(query.statement, 'SELECT * FROM users WHERE age <= 34.3;');
      });

      test('in', () {
        final query = Query.make('users', driver)
            .where('places', 'in', ['Accra', 'Tema']);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IN (\'Accra\', \'Tema\');',
        );
      });

      test('not in', () {
        final query = Query.make('users', driver)
            .where('places', 'not in', ['Accra', 'Tema']);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tema\');',
        );
      });

      test('null', () {
        final query = Query.make('users', driver).where('places', 'null');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IS NULL;',
        );
      });

      test('not null', () {
        final query = Query.make('users', driver).where('places', 'not null');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IS NOT NULL;',
        );
      });

      test('like', () {
        final query =
            Query.make('users', driver).where('places', 'like', "MerryC");

        expect(
          query.statement,
          'SELECT * FROM users WHERE places LIKE \'MerryC\';',
        );
      });

      test('not like', () {
        final query =
            Query.make('users', driver).where('places', 'not like', "MerryC");

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT LIKE \'MerryC\';',
        );
      });

      test('between', () {
        final query =
            Query.make('users', driver).where('age', 'between', [22, 30]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE age BETWEEN 22 AND 30;',
        );
      });

      test('not between', () {
        final query =
            Query.make('users', driver).where('age', 'not between', [22, 30]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE age NOT BETWEEN 22 AND 30;',
        );
      });
    });
  });
}
