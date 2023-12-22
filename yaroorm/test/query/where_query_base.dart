import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/query/query.dart';

void whereTestGroup(DatabaseDriver driver) => group('with ${driver.type.name} Driver', () {
      group('when .where', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).where('firstname', '=', 'Chima');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\';',
          );
        });

        test('of level 2', () {
          final query =
              Query.query('users').driver(driver).where('firstname', '=', 'Chima').where('lastname', '=', 'Precious');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname = \'Precious\';',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
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
            final query = Query.query('users').driver(driver).where('firstname', '=', 'Chima').orWhere('age', '=', 203);

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203;',
            );
          });

          test('of level 2', () {
            final query = Query.query('users')
                .driver(driver)
                .where('firstname', '=', 'Chima')
                .orWhere('age', '=', 203)
                .where('city', '!=', 'Accra');

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' OR (age = 203 AND city != \'Accra\');',
            );
          });

          test('of level 3', () {
            final query = Query.query('users')
                .driver(driver)
                .where('votes', '>', 100)
                .orWhere('name', '=', 'Abigail')
                .where('votes', '>', 50);

            expect(
              query.statement,
              'SELECT * FROM users WHERE votes > 100 OR (name = \'Abigail\' AND votes > 50);',
            );
          });

          test('of level 4', () {
            final query = Query.query('users')
                .driver(driver)
                .where('firstname', '=', 'Chima')
                .orWhere('age', '=', 203)
                .orWhere('city', '!=', 'Accra')
                .where('name', 'like', 'Chima%');

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' OR (age = 203 OR city != \'Accra\' AND name LIKE \'Chima%\');',
            );
          });

          test('of level 4', () {
            final query = Query.query('users')
                .driver(driver)
                .where('firstname', '=', 'Chima')
                .orWhere('age', '=', 203)
                .orWhere('city', '!=', 'Accra')
                .where('name', 'like', 'Chima%')
                .where('sizes', 'between', [12, 23]);

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' OR (age = 203 OR city != \'Accra\' AND name LIKE \'Chima%\' AND sizes BETWEEN 12 AND 23);',
            );
          });
        });

        group('chained with', () {
          test('.whereNull', () {
            final query = Query.query('users').driver(driver).where('firstname', '=', 'Chima').whereNull('age');

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND age IS NULL;',
            );
          });

          test('.whereNotNull', () {
            final query = Query.query('users').driver(driver).where('firstname', '=', 'Chima').whereNotNull('age');

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND age IS NOT NULL;',
            );
          });

          test('.whereIn', () {
            final query =
                Query.query('users').driver(driver).where('firstname', '=', 'Chima').whereIn('age', [22, 24, 25]);

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND age IN (22, 24, 25);',
            );
          });

          test('.whereNotIn', () {
            final query =
                Query.query('users').driver(driver).where('firstname', '=', 'Chima').whereNotIn('age', [22, 24, 25]);

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND age NOT IN (22, 24, 25);',
            );
          });

          test('.whereLike', () {
            final query =
                Query.query('users').driver(driver).where('firstname', '=', 'Chima').whereLike('lastname', 'hello%');

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname LIKE \'hello%\';',
            );
          });

          test('.whereNotLike', () {
            final query =
                Query.query('users').driver(driver).where('firstname', '=', 'Chima').whereNotLike('lastname', 'hello%');

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname NOT LIKE \'hello%\';',
            );
          });

          test('.whereBetween', () {
            final query = Query.query('users')
                .driver(driver)
                .where('firstname', '=', 'Chima')
                .whereBetween<int>('lastname', [22, 50]);

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname BETWEEN 22 AND 50;',
            );
          });

          test('.whereNotBetween', () {
            final query = Query.query('users')
                .driver(driver)
                .where('firstname', '=', 'Chima')
                .whereNotBetween<double>('lastname', [22.34, 50]);

            expect(
              query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname NOT BETWEEN 22.34 AND 50.0;',
            );
          });
        });
      });

      group('when handwritten operator', () {
        test('=', () {
          final query = Query.query('users').driver(driver).where('firstname', '=', 'Chima');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\';',
          );
        });

        test('!=', () {
          final query = Query.query('users').driver(driver).where('firstname', '!=', 'Chima');

          expect(query.statement, 'SELECT * FROM users WHERE firstname != \'Chima\';');
        });

        test('>', () {
          final query = Query.query('users').driver(driver).where('age', '>', 23);

          expect(query.statement, 'SELECT * FROM users WHERE age > 23;');
        });

        test('<', () {
          final query = Query.query('users').driver(driver).where('age', '<', 23);

          expect(query.statement, 'SELECT * FROM users WHERE age < 23;');
        });

        test('>=', () {
          final query = Query.query('users').driver(driver).where('age', '>=', 223);

          expect(query.statement, 'SELECT * FROM users WHERE age >= 223;');
        });

        test('<=', () {
          final query = Query.query('users').driver(driver).where('age', '<=', 34.3);

          expect(query.statement, 'SELECT * FROM users WHERE age <= 34.3;');
        });

        test('in', () {
          final query = Query.query('users').driver(driver).where('places', 'in', ['Accra', 'Tema']);

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IN (\'Accra\', \'Tema\');',
          );
        });

        test('not in', () {
          final query = Query.query('users').driver(driver).where('places', 'not in', ['Accra', 'Tema']);

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tema\');',
          );
        });

        test('null', () {
          final query = Query.query('users').driver(driver).where('places', 'null');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IS NULL;',
          );
        });

        test('not null', () {
          final query = Query.query('users').driver(driver).where('places', 'not null');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IS NOT NULL;',
          );
        });

        test('like', () {
          final query = Query.query('users').driver(driver).where('places', 'like', "MerryC");

          expect(
            query.statement,
            'SELECT * FROM users WHERE places LIKE \'MerryC\';',
          );
        });

        test('not like', () {
          final query = Query.query('users').driver(driver).where('places', 'not like', "MerryC");

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT LIKE \'MerryC\';',
          );
        });

        test('between', () {
          final query = Query.query('users').driver(driver).where('age', 'between', [22, 30]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE age BETWEEN 22 AND 30;',
          );
        });

        test('not between', () {
          final query = Query.query('users').driver(driver).where('age', 'not between', [22, 30]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE age NOT BETWEEN 22 AND 30;',
          );
        });
      });

      group('when .whereIn', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereIn('firstname', ['Accra', 'Tamale']);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname IN (\'Accra\', \'Tamale\');',
          );
        });

        test('of level 2', () {
          final query = Query.query('users')
              .driver(driver)
              .whereIn('places', ['Accra', 'Tamale']).where('lastname', '=', 'Precious');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\';',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
              .whereIn('places', ['Accra', 'Tamale'])
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\' AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereIn('places', ['Accra', 'Tamale'])
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%')
              .orWhere('age', 'in', [23, 34, 55]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\' AND names LIKE \'Hello%\') OR age IN (23, 34, 55);',
          );
        });
      });

      group('when .whereNotIn', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereNotIn('firstname', ['Accra', 'Tamale']);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname NOT IN (\'Accra\', \'Tamale\');',
          );
        });

        test('of level 2', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotIn('places', ['Accra', 'Tamale']).where('lastname', '=', 'Precious');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\';',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotIn('places', ['Accra', 'Tamale'])
              .where('lastname', '=', 'Precious')
              .whereNotNull('names');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\' AND names IS NOT NULL;',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotIn('places', ['Accra', 'Tamale'])
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%')
              .whereBetween('age', [23, 34]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\' AND names LIKE \'Hello%\' AND age BETWEEN 23 AND 34;',
          );
        });
      });

      group('when .whereBetween', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereBetween('age', [22, 70]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE age BETWEEN 22 AND 70;',
          );
        });

        test('of level 2', () {
          final query = Query.query('users')
              .driver(driver)
              .whereBetween('places', ['Accra', 'Tamale']).where('lastname', 'between', [2, 100]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE places BETWEEN \'Accra\' AND \'Tamale\' AND lastname BETWEEN 2 AND 100;',
          );
        });

        test('of level 3', () {
          final query = Query.query('users').driver(driver).whereIn('places', ['Accra', 'Tamale']).whereBetween(
              'lastname', [22, 48]).where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname BETWEEN 22 AND 48 AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereIn('places', ['Accra', 'Tamale'])
              .where('lastname', '=', 'Precious')
              .orWhere('age', 'in', [23, 34, 55])
              .whereBetween('dates', ['2015-01-01', '2016-12-01']);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\') OR (age IN (23, 34, 55) AND dates BETWEEN \'2015-01-01\' AND \'2016-12-01\');',
          );
        });
      });

      group('when .whereNotBetween', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereNotBetween('age', [22, 70]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE age NOT BETWEEN 22 AND 70;',
          );
        });

        test('of level 2', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotBetween('places', ['Accra', 'Tamale']).where('lastname', 'between', [2, 100]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT BETWEEN \'Accra\' AND \'Tamale\' AND lastname BETWEEN 2 AND 100;',
          );
        });

        test('of level 3', () {
          final query = Query.query('users').driver(driver).whereIn('places', ['Accra', 'Tamale']).whereNotBetween(
              'lastname', [22, 48]).where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname NOT BETWEEN 22 AND 48 AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereIn('places', ['Accra', 'Tamale'])
              .where('lastname', '=', 'Precious')
              .orWhere('age', 'in', [23, 34, 55])
              .whereNotBetween('dates', ['2015-01-01', '2016-12-01']);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\') OR (age IN (23, 34, 55) AND dates NOT BETWEEN \'2015-01-01\' AND \'2016-12-01\');',
          );
        });
      });

      group('when .whereLike', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereLike('firstname', 'Names%%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname LIKE \'Names%%\';',
          );
        });

        test('of level 2', () {
          final query =
              Query.query('users').driver(driver).whereLike('places', 'Chima**').where('lastname', '=', 'Precious');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places LIKE \'Chima**\' AND lastname = \'Precious\';',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
              .whereLike('places', 'Hello123')
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places LIKE \'Hello123\' AND lastname = \'Precious\' AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereLike('places', 'Nems#')
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%')
              .orWhere('age', 'between', [23, 34]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places LIKE \'Nems#\' AND lastname = \'Precious\' AND names LIKE \'Hello%\') OR age BETWEEN 23 AND 34;',
          );
        });
      });

      group('when .whereNotLike', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereNotLike('firstname', 'Names%%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname NOT LIKE \'Names%%\';',
          );
        });

        test('of level 2', () {
          final query =
              Query.query('users').driver(driver).whereNotLike('places', 'Chima**').whereBetween('lastname', [12, 90]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT LIKE \'Chima**\' AND lastname BETWEEN 12 AND 90;',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotLike('places', 'Hello123')
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places NOT LIKE \'Hello123\' AND lastname = \'Precious\' AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotLike('places', 'Nems#')
              .where('lastname', '=', 'Precious')
              .orWhere('names', 'not like', 'Hello%')
              .orWhere('age', 'between', [23, 34]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places NOT LIKE \'Nems#\' AND lastname = \'Precious\') OR (names NOT LIKE \'Hello%\' OR age BETWEEN 23 AND 34);',
          );
        });
      });

      group('when .whereNull', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereNull('firstname');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname IS NULL;',
          );
        });

        test('of level 2', () {
          final query = Query.query('users').driver(driver).whereNull('places').where('lastname', '=', 'Precious');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IS NULL AND lastname = \'Precious\';',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNull('places')
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IS NULL AND lastname = \'Precious\' AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNull('places')
              .where('lastname', '=', 'Precious')
              .orWhere('names', 'null')
              .orWhere('age', 'between', [23, 34]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places IS NULL AND lastname = \'Precious\') OR (names IS NULL OR age BETWEEN 23 AND 34);',
          );
        });
      });

      group('when .whereNotNull', () {
        test('of level 1', () {
          final query = Query.query('users').driver(driver).whereNotNull('firstname');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname IS NOT NULL;',
          );
        });

        test('of level 2', () {
          final query = Query.query('users').driver(driver).whereNotNull('places').where('lastname', '=', 'Precious');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IS NOT NULL AND lastname = \'Precious\';',
          );
        });

        test('of level 3', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotNull('places')
              .where('lastname', '=', 'Precious')
              .where('names', 'like', 'Hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE places IS NOT NULL AND lastname = \'Precious\' AND names LIKE \'Hello%\';',
          );
        });

        test('of level 4', () {
          final query = Query.query('users')
              .driver(driver)
              .whereNotNull('places')
              .where('lastname', '=', 'Precious')
              .orWhere('names', 'not null')
              .orWhere('age', 'between', [23, 34]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE (places IS NOT NULL AND lastname = \'Precious\') OR (names IS NOT NULL OR age BETWEEN 23 AND 34);',
          );
        });
      });

      test('when .whereFunc', () {
        final query = Query.query('users')
            .driver(driver)
            .where('name', '=', 'John')
            .whereFunc(($query) => $query.where('votes', '>', 100).orWhere('title', '=', 'Admin'));

        expect(
          query.statement,
          'SELECT * FROM users WHERE (name = \'John\' AND votes > 100) OR title = \'Admin\';',
        );
      });

      test('when .orWhereFunc', () {
        final query = Query.query('users')
            .driver(driver)
            .where('votes', '>', 100)
            .orWhereFunc(($query) => $query.where('name', '=', 'Abigail').where('votes', '>', 50));

        expect(
          query.statement,
          'SELECT * FROM users WHERE votes > 100 OR (name = \'Abigail\' AND votes > 50);',
        );
      });
    });
