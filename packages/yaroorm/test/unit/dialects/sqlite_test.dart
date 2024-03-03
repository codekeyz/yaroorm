import 'package:test/test.dart';
import 'package:yaroorm/migration.dart';
import 'package:yaroorm/src/database/driver/sqlite_driver.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../integration/fixtures/orm_config.dart' as db;
import '../../integration/fixtures/test_data.dart';
import 'sqlite_test.reflectable.dart';

@Table(name: 'user_articles', primaryKey: '_id_')
class Article extends Entity<int, Entity> {
  final String name;
  final int ownerId;

  Article(this.name, this.ownerId);
}

class ArticleComment extends Entity<String, ArticleComment> {
  final int articleId;
  final int userId;

  ArticleComment(this.articleId, this.userId);
}

void main() {
  initializeReflectable();

  DB.init(db.config);

  late DatabaseDriver driver;

  setUpAll(() => driver = DB.driver('foo_sqlite'));

  group('SQLITE Query Builder', () {
    test('when query', () {
      final query = Query.table('users').driver(driver);

      expect(query.statement, 'SELECT * FROM users;');
    });

    test('when query with single orderBy', () {
      final query = Query.table('users').driver(driver).orderByDesc('names');

      expect(query.statement, 'SELECT * FROM users ORDER BY names DESC;');
    });

    test('when query with multiple orderBy', () {
      final query = Query.table('users')
          .driver(driver)
          .orderByDesc('names')
          .orderByAsc('ages');

      expect(query.statement,
          'SELECT * FROM users ORDER BY names DESC, ages ASC;');
    });

    test('when update', () {
      final query = Query.table('users').driver(driver).update(
        where: (where) => where.where('name', '=', 'Chima'),
        values: {'firstname': 'Chima', 'lastname': 'Precious'},
      );

      expect(query.statement,
          'UPDATE users SET firstname = ?, lastname = ? WHERE name = \'Chima\';');
    });

    test('when delete', () {
      final query = Query.table('users')
          .driver(driver)
          .delete((where) => where.where('name', '=', 'Chima'));

      expect(query.statement, 'DELETE FROM users WHERE name = \'Chima\';');
    });

    group('when .where', () {
      test('of level 1', () {
        final query = Query.table('users')
            .driver(driver)
            .where('firstname', '=', 'Chima');

        expect(query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\';');
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .where('firstname', '=', 'Chima')
            .where('lastname', '=', 'Precious');

        expect(query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname = \'Precious\';');
      });

      test('of level 3', () {
        final query = Query.table('users')
            .driver(driver)
            .where('firstname', '=', 'Chima')
            .where('lastname', '=', 'Precious')
            .where('age', '=', 22);

        expect(query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname = \'Precious\' AND age = 22;');
      });

      group('chained with `.orWhere`', () {
        test('of level 1', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203);

          expect(query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203;');
        });

        test('of level 2', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .where('city', '!=', 'Accra');

          expect(query.statement,
              'SELECT * FROM users WHERE firstname = \'Chima\' OR (age = 203 AND city != \'Accra\');');
        });

        test('of level 3', () {
          final query = Query.table('users')
              .driver(driver)
              .where('votes', '>', 100)
              .orWhere('name', '=', 'Abigail')
              .where('votes', '>', 50);

          expect(query.statement,
              'SELECT * FROM users WHERE votes > 100 OR (name = \'Abigail\' AND votes > 50);');
        });

        test('of level 4', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .orWhere('city', '!=', 'Accra')
              .where('name', 'like', 'Chima%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203 OR (city != \'Accra\' AND name LIKE \'Chima%\');',
          );
        });

        test('of level 5', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .orWhere('age', '=', 203)
              .orWhere('city', '!=', 'Accra')
              .where('name', 'like', 'Chima%')
              .where('sizes', 'between', [12, 23]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' OR age = 203 OR (city != \'Accra\' AND name LIKE \'Chima%\' AND sizes BETWEEN 12 AND 23);',
          );
        });
      });

      group('chained with', () {
        test('.whereNull', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereNull('age');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age IS NULL;',
          );
        });

        test('.whereNotNull', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereNotNull('age');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age IS NOT NULL;',
          );
        });

        test('.whereIn', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereIn('age', [22, 24, 25]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age IN (22, 24, 25);',
          );
        });

        test('.whereNotIn', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereNotIn('age', [22, 24, 25]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND age NOT IN (22, 24, 25);',
          );
        });

        test('.whereLike', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereLike('lastname', 'hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname LIKE \'hello%\';',
          );
        });

        test('.whereNotLike', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereNotLike('lastname', 'hello%');

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname NOT LIKE \'hello%\';',
          );
        });

        test('.whereBetween', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereBetween<int>('lastname', [22, 50]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname BETWEEN 22 AND 50;',
          );
        });

        test('.whereNotBetween', () {
          final query = Query.table('users')
              .driver(driver)
              .where('firstname', '=', 'Chima')
              .whereNotBetween<double>('lastname', [22.34, 50]);

          expect(
            query.statement,
            'SELECT * FROM users WHERE firstname = \'Chima\' AND lastname NOT BETWEEN 22.34 AND 50.0;',
          );
        });
      });

      test('with orderBy', () {
        final query = Query.table('users')
            .driver(driver)
            .where('name', '=', 'Chima')
            .orderByDesc('names')
            .orderByAsc('ages');

        expect(query.statement,
            'SELECT * FROM users WHERE name = \'Chima\' ORDER BY names DESC, ages ASC;');
      });
    });

    group('when handwritten operator', () {
      test('should error if unknown operator', () {
        expect(
            () => Query.table('users')
                .driver(driver)
                .where('age', 'foo-bar', '23')
                .statement,
            throwsA(isA<ArgumentError>().having(
                (p0) => p0.message, '', 'Condition foo-bar is not known')));
      });

      test('=', () {
        final query = Query.table('users')
            .driver(driver)
            .where('firstname', '=', 'Chima');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname = \'Chima\';',
        );
      });

      test('!=', () {
        final query = Query.table('users')
            .driver(driver)
            .where('firstname', '!=', 'Chima');

        expect(query.statement,
            'SELECT * FROM users WHERE firstname != \'Chima\';');
      });

      test('>', () {
        final query = Query.table('users').driver(driver).where('age', '>', 23);

        expect(query.statement, 'SELECT * FROM users WHERE age > 23;');
      });

      test('<', () {
        final query = Query.table('users').driver(driver).where('age', '<', 23);

        expect(query.statement, 'SELECT * FROM users WHERE age < 23;');
      });

      test('>=', () {
        final query =
            Query.table('users').driver(driver).where('age', '>=', 223);

        expect(query.statement, 'SELECT * FROM users WHERE age >= 223;');
      });

      test('<=', () {
        final query =
            Query.table('users').driver(driver).where('age', '<=', 34.3);

        expect(query.statement, 'SELECT * FROM users WHERE age <= 34.3;');
      });

      test('in', () {
        final query = Query.table('users')
            .driver(driver)
            .where('places', 'in', ['Accra', 'Tema']);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IN (\'Accra\', \'Tema\');',
        );
      });

      test('not in', () {
        final query = Query.table('users')
            .driver(driver)
            .where('places', 'not in', ['Accra', 'Tema']);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tema\');',
        );
      });

      test('null', () {
        final query =
            Query.table('users').driver(driver).where('places', 'null');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IS NULL;',
        );
      });

      test('not null', () {
        final query =
            Query.table('users').driver(driver).where('places', 'not null');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IS NOT NULL;',
        );
      });

      test('like', () {
        final query = Query.table('users')
            .driver(driver)
            .where('places', 'like', "MerryC");

        expect(
          query.statement,
          'SELECT * FROM users WHERE places LIKE \'MerryC\';',
        );
      });

      test('not like', () {
        final query = Query.table('users')
            .driver(driver)
            .where('places', 'not like', "MerryC");

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT LIKE \'MerryC\';',
        );
      });

      test('between', () {
        final query = Query.table('users')
            .driver(driver)
            .where('age', 'between', [22, 30]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE age BETWEEN 22 AND 30;',
        );
      });

      test('not between', () {
        final query = Query.table('users')
            .driver(driver)
            .where('age', 'not between', [22, 30]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE age NOT BETWEEN 22 AND 30;',
        );
      });
    });

    group('when .whereIn', () {
      test('of level 1', () {
        final query = Query.table('users')
            .driver(driver)
            .whereIn('firstname', ['Accra', 'Tamale']);

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname IN (\'Accra\', \'Tamale\');',
        );
      });

      test('of level 2', () {
        final query = Query.table('users').driver(driver).whereIn(
            'places', ['Accra', 'Tamale']).where('lastname', '=', 'Precious');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\';',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
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
        final query = Query.table('users')
            .driver(driver)
            .whereNotIn('firstname', ['Accra', 'Tamale']);

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname NOT IN (\'Accra\', \'Tamale\');',
        );
      });

      test('of level 2', () {
        final query = Query.table('users').driver(driver).whereNotIn(
            'places', ['Accra', 'Tamale']).where('lastname', '=', 'Precious');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT IN (\'Accra\', \'Tamale\') AND lastname = \'Precious\';',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
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
      test('should error if not supplied List with length 2', () {
        expect(
            () => Query.table('users')
                .driver(driver)
                .whereBetween('age', [22]).statement,
            throwsA(isA<ArgumentError>().having((p0) => p0.message, '',
                'BETWEEN requires a List with length 2 (val1, val2)')));
      });

      test('of level 1', () {
        final query =
            Query.table('users').driver(driver).whereBetween('age', [22, 70]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE age BETWEEN 22 AND 70;',
        );
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .whereBetween('places', ['Accra', 'Tamale']).where(
                'lastname', 'between', [2, 100]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places BETWEEN \'Accra\' AND \'Tamale\' AND lastname BETWEEN 2 AND 100;',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
            .driver(driver)
            .whereIn('places', ['Accra', 'Tamale']).whereBetween(
                'lastname', [22, 48]).where('names', 'like', 'Hello%');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname BETWEEN 22 AND 48 AND names LIKE \'Hello%\';',
        );
      });

      test('of level 4', () {
        final query = Query.table('users')
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
      test('should error if not supplied List with length 2', () {
        expect(
            () => Query.table('users')
                .driver(driver)
                .whereNotBetween('age', [22]).statement,
            throwsA(isA<ArgumentError>().having((p0) => p0.message, '',
                'NOT_BETWEEN requires a List with length 2 (val1, val2)')));
      });

      test('of level 1', () {
        final query = Query.table('users')
            .driver(driver)
            .whereNotBetween('age', [22, 70]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE age NOT BETWEEN 22 AND 70;',
        );
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .whereNotBetween('places', ['Accra', 'Tamale']).where(
                'lastname', 'between', [2, 100]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT BETWEEN \'Accra\' AND \'Tamale\' AND lastname BETWEEN 2 AND 100;',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
            .driver(driver)
            .whereIn('places', ['Accra', 'Tamale']).whereNotBetween(
                'lastname', [22, 48]).where('names', 'like', 'Hello%');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IN (\'Accra\', \'Tamale\') AND lastname NOT BETWEEN 22 AND 48 AND names LIKE \'Hello%\';',
        );
      });

      test('of level 4', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
            .driver(driver)
            .whereLike('firstname', 'Names%%');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname LIKE \'Names%%\';',
        );
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .whereLike('places', 'Chima**')
            .where('lastname', '=', 'Precious');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places LIKE \'Chima**\' AND lastname = \'Precious\';',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
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
        final query = Query.table('users')
            .driver(driver)
            .whereNotLike('firstname', 'Names%%');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname NOT LIKE \'Names%%\';',
        );
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .whereNotLike('places', 'Chima**')
            .whereBetween('lastname', [12, 90]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE places NOT LIKE \'Chima**\' AND lastname BETWEEN 12 AND 90;',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
            .driver(driver)
            .whereNotLike('places', 'Nems#')
            .where('lastname', '=', 'Precious')
            .orWhere('names', 'not like', 'Hello%')
            .orWhere('age', 'between', [23, 34]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE (places NOT LIKE \'Nems#\' AND lastname = \'Precious\') OR names NOT LIKE \'Hello%\' OR age BETWEEN 23 AND 34;',
        );
      });
    });

    group('when .whereNull', () {
      test('of level 1', () {
        final query =
            Query.table('users').driver(driver).whereNull('firstname');

        expect(query.statement, 'SELECT * FROM users WHERE firstname IS NULL;');
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .whereNull('places')
            .where('lastname', '=', 'Precious');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IS NULL AND lastname = \'Precious\';',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
            .driver(driver)
            .whereNull('places')
            .where('lastname', '=', 'Precious')
            .orWhere('names', 'null')
            .orWhere('age', 'between', [23, 34]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE (places IS NULL AND lastname = \'Precious\') OR names IS NULL OR age BETWEEN 23 AND 34;',
        );
      });
    });

    group('when .whereNotNull', () {
      test('of level 1', () {
        final query =
            Query.table('users').driver(driver).whereNotNull('firstname');

        expect(
          query.statement,
          'SELECT * FROM users WHERE firstname IS NOT NULL;',
        );
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .whereNotNull('places')
            .where('lastname', '=', 'Precious');

        expect(
          query.statement,
          'SELECT * FROM users WHERE places IS NOT NULL AND lastname = \'Precious\';',
        );
      });

      test('of level 3', () {
        final query = Query.table('users')
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
        final query = Query.table('users')
            .driver(driver)
            .whereNotNull('places')
            .where('lastname', '=', 'Precious')
            .orWhere('names', 'not null')
            .orWhere('age', 'between', [23, 34]);

        expect(
          query.statement,
          'SELECT * FROM users WHERE (places IS NOT NULL AND lastname = \'Precious\') OR names IS NOT NULL OR age BETWEEN 23 AND 34;',
        );
      });
    });

    test('when .whereFunc', () {
      final query = Query.table('users')
          .driver(driver)
          .where('name', '=', 'John')
          .whereFunc((query) =>
              query.where('votes', '>', 100).orWhere('title', '=', 'Admin'));

      expect(
        query.statement,
        'SELECT * FROM users WHERE name = \'John\' AND (votes > 100 OR title = \'Admin\');',
      );
    });

    group('when .orWhereFunc', () {
      test('of level 1', () {
        final query = Query.table('users')
            .driver(driver)
            .where('votes', '>', 100)
            .orWhereFunc((query) =>
                query.where('name', '=', 'Abigail').where('votes', '>', 50));

        expect(
          query.statement,
          'SELECT * FROM users WHERE votes > 100 OR (name = \'Abigail\' AND votes > 50);',
        );
      });

      test('of level 2', () {
        final query = Query.table('users')
            .driver(driver)
            .where('votes', '>', 100)
            .orWhereFunc((query) =>
                query.where('name', '=', 'Abigail').where('votes', '>', 50))
            .orWhereFunc((query) =>
                query.where('price', '=', 'GHC200').where('votes', 'not null'));

        expect(
          query.statement,
          'SELECT * FROM users WHERE votes > 100 OR (name = \'Abigail\' AND votes > 50) OR (price = \'GHC200\' AND votes IS NOT NULL);',
        );
      });

      test('or level 3', () {
        var query = Query.table('users')
            .driver(driver)
            .where('votes', '>', 100)
            .orWhereFunc((query) =>
                query.where('name', '=', 'Abigail').where('votes', '>', 50))
            .where('name', '=', 22)
            .orWhereFunc((query) => query.where('name', '=', 'Abigail'));

        expect(
          query.statement,
          'SELECT * FROM users WHERE votes > 100 OR (name = \'Abigail\' AND votes > 50) AND name = 22 OR name = \'Abigail\';',
        );
      });
    });

    group('.whereFunc or .orWhereFunc', () {
      group('when used at start of query', () {
        test('when .orWhereFunc', () {
          expect(
            () => Query.table('users')
                .driver(driver)
                .orWhereFunc((query) => query.where('name', '=', 'Abigail')),
            throwsStateError,
          );
        });

        test('when .whereFunc', () {
          var query = Query.table('users')
              .driver(driver)
              .whereFunc((query) => query.where('name', '=', 'Abigail'));

          expect(
            query.statement,
            'SELECT * FROM users WHERE name = \'Abigail\';',
          );
        });
      });

      test('when used together', () {
        var query = Query.table('users')
            .driver(driver)
            .whereFunc((query) => query.where('name', '=', 'Abigail'))
            .orWhereFunc((query) =>
                query.where('age', '<', 24).where('names', 'not null'));

        expect(
          query.statement,
          'SELECT * FROM users WHERE name = \'Abigail\' OR (age < 24 AND names IS NOT NULL);',
        );
      });

      group('when nested crazy', () {
        test('with level 1', () {
          final query = Query.table('users')
              .driver(driver)
              .where('name', '=', 'Chima')
              .orWhereFunc(
                (query) => query
                    .where('biscuit', '=', 'hello-world')
                    .orWhere('car_type', '=', 'lamborgini server')
                    .where('image', 'like', 'Image&&'),
              );

          expect(
            query.statement,
            "SELECT * FROM users WHERE name = 'Chima' OR (biscuit = 'hello-world' OR (car_type = 'lamborgini server' AND image LIKE 'Image&&'));",
          );
        });

        test('with level 2', () {
          final query = Query.table('users')
              .driver(driver)
              .where('name', '=', 'Chima')
              .orWhereFunc(
                (query) => query
                    .where('biscuit', '=', 'hello-world')
                    .orWhere('car_type', '=', 'lamborgini server')
                    .where('image', 'like', 'Image&&'),
              )
              .whereFunc((query) => query
                  .whereIn('fruits', ['oranges', 'apples'])
                  .whereBetween('price', [20, 100])
                  .whereEqual('status', 'available')
                  .whereLike('stores', 'Accra, %%'));

          final sB = StringBuffer();
          sB.write("SELECT * FROM users WHERE name = 'Chima' ");
          sB.write(
              "OR (biscuit = 'hello-world' OR (car_type = 'lamborgini server' AND image LIKE 'Image&&')) ");
          sB.write(
              "AND (fruits IN ('oranges', 'apples') AND price BETWEEN 20 AND 100 AND status = 'available' AND stores LIKE 'Accra, %%');");

          expect(query.statement, sB.toString());
        });

        test('with level 3', () {
          final query = Query.table('users')
              .driver(driver)
              .where('name', '=', 'Chima')
              .orWhereFunc(
                (query) => query
                    .where('biscuit', '=', 'hello-world')
                    .orWhere('car_type', '=', 'lamborgini server')
                    .where('image', 'like', 'Image&&'),
              )
              .whereFunc((query) => query
                  .whereIn('fruits', ['oranges', 'apples'])
                  .whereBetween('price', [20, 100])
                  .whereEqual('status', 'available')
                  .whereLike('stores', 'Accra, %%'))
              .orWhereFunc((query) => query
                  .where('languages', 'in', ['python', 'cobra']).orWhereFunc(
                      (query) => query
                          .where('job_status', '=', 'available')
                          .where('location', '=', 'Accra')
                          .whereNotBetween('salary', [8000, 16000])));

          final sB = StringBuffer();
          sB.write("SELECT * FROM users WHERE name = 'Chima' ");
          sB.write(
              "OR (biscuit = 'hello-world' OR (car_type = 'lamborgini server' AND image LIKE 'Image&&')) ");
          sB.write(
              "AND (fruits IN ('oranges', 'apples') AND price BETWEEN 20 AND 100 AND status = 'available' AND stores LIKE 'Accra, %%') ");
          sB.write(
              "OR (languages IN ('python', 'cobra') OR (job_status = 'available' AND location = 'Accra' AND salary NOT BETWEEN 8000 AND 16000));");

          expect(query.statement, sB.toString());
        });
      });
    });
  });

  group('SQLITE Table Blueprint', () {
    //
    group('`foreignKey` should resolve for ', () {
      //
      test('class with entity meta', () {
        final blueprint = SqliteTableBlueprint()
          ..string('name')
          ..integer('userId');

        late ForeignKey key;
        blueprint.foreign<Article, User>(onKey: (fkey) => key = fkey);

        expect(key.table, 'user_articles');
        expect(key.column, 'userId');
        expect(key.foreignTable, 'users');
        expect(key.foreignTableColumn, 'id');
      });

      test('class with no meta', () {
        final blueprint = SqliteTableBlueprint()..string('userId');

        late ForeignKey key;
        blueprint.foreign<ArticleComment, User>(onKey: (fkey) => key = fkey);

        expect(key.table, 'article_comments');
        expect(key.column, 'userId');
        expect(key.foreignTable, 'users');
        expect(key.foreignTableColumn, 'id');
      });

      test('custom foreign reference column', () {
        final blueprint = SqliteTableBlueprint()..string('articleId');

        late ForeignKey key;
        blueprint.foreign<ArticleComment, Article>(
            column: 'articleId', onKey: (fkey) => key = fkey);

        expect(key.table, 'article_comments');
        expect(key.column, 'articleId');
        expect(key.foreignTable, 'user_articles');
        expect(key.foreignTableColumn, '_id_');
      });

      test('should make statement', () {
        final blueprint = SqliteTableBlueprint()
          ..string('name')
          ..integer('userId');

        late ForeignKey key;
        blueprint.foreign<Article, User>(onKey: (fkey) => key = fkey);

        final statement = SqliteSerializer().acceptForeignKey(blueprint, key);
        expect(statement, 'FOREIGN KEY (userId) REFERENCES users(id)');
      });

      test('when custom reference actions', () {
        final blueprint = SqliteTableBlueprint()
          ..string('name')
          ..integer('userId');

        late ForeignKey key;
        blueprint.foreign<Article, User>(
          onKey: (fkey) => key = fkey.actions(
              onUpdate: ForeignKeyAction.cascade,
              onDelete: ForeignKeyAction.setNull),
        );

        final statement = SqliteSerializer().acceptForeignKey(blueprint, key);
        expect(statement,
            'FOREIGN KEY (userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL');
      });

      group('when constrained', () {
        test('with no specified name', () {
          final blueprint = SqliteTableBlueprint()
            ..string('name')
            ..integer('userId');

          late ForeignKey key;
          blueprint.foreign<Article, User>(
              onKey: (fkey) => key = fkey.constrained());

          final statement = SqliteSerializer().acceptForeignKey(blueprint, key);
          expect(
            statement,
            'CONSTRAINT fk_user_articles_userId_to_users_id FOREIGN KEY (userId) REFERENCES users(id)',
          );
        });

        test('with specified name', () {
          final blueprint = SqliteTableBlueprint()
            ..string('name')
            ..integer('ownerId');

          late ForeignKey key;
          blueprint.foreign<Article, User>(
              column: 'ownerId',
              onKey: (fkey) => key = fkey
                  .actions(
                      onUpdate: ForeignKeyAction.cascade,
                      onDelete: ForeignKeyAction.setNull)
                  .constrained(name: 'fk_articles_users'));

          final statement = SqliteSerializer().acceptForeignKey(blueprint, key);
          expect(statement,
              'CONSTRAINT fk_articles_users FOREIGN KEY (ownerId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL');
        });

        test('should serialize foreign key in schema', () {
          var schema = Schema.create('articles', (table) {
            return table
              ..id()
              ..string('userId')
              ..foreign<Article, User>(
                  onKey: (key) => key.constrained(name: 'some_constraint'));
          });

          expect(
            schema.toScript(driver.blueprint),
            'CREATE TABLE articles (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, userId VARCHAR NOT NULL, CONSTRAINT some_constraint FOREIGN KEY (userId) REFERENCES users(id));',
          );

          schema = Schema.create('articles', (table) {
            return table
              ..id(autoIncrement: false)
              ..string('ownerId')
              ..foreign<Article, User>(
                  column: 'ownerId',
                  onKey: (key) => key
                      .constrained(name: 'some_constraint')
                      .actions(
                          onUpdate: ForeignKeyAction.cascade,
                          onDelete: ForeignKeyAction.cascade));
          });

          expect(
            schema.toScript(driver.blueprint),
            'CREATE TABLE articles (id INTEGER NOT NULL PRIMARY KEY, ownerId VARCHAR NOT NULL, CONSTRAINT some_constraint FOREIGN KEY (ownerId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE);',
          );
        });
      });
    });
  });
}
