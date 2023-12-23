import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../../helpers/drivers.dart';

void main() {
  late DatabaseDriver driver;
  late DatabaseDriver postgresSqlDriver;

  setUpAll(() {
    driver = DatabaseDriver.init(sqliteConnection);
    postgresSqlDriver = DatabaseDriver.init(postgresSqlConnection);
  });

  group('SQLite Query.query', () {
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

  group('Postgre Query.query', () {

    group('Create tables', () {
      test('Check for users table', () async {
        // Generate the SQL command for creating the table
        postgresSqlDriver.connect();
        var blueprint = postgresSqlDriver.blueprint;
        blueprint.id(name: 'id');
        blueprint.string('username');
        blueprint.string('email');
        blueprint.string('password');
        String createTableCommand = blueprint.createScript('users');

        // Execute the SQL command
       // await postgresSqlDriver.execute(createTableCommand);

        print(createTableCommand);

        // Check if the table was created successfully
        bool tableExists = await postgresSqlDriver.hasTable('users');
        expect(tableExists, isTrue);
        //expect(createTableCommand, isTrue);
      });

      // Add more test cases for other tables...
    });

    group('when `.orderByAsc`', () {
      test(' of level 1', () {
        expect(
          Query.query('users', postgresSqlDriver).orderByAsc('firstname').statement,
          'SELECT * FROM users ORDER BY firstname ASC;',
        );
      });

      test(' of level 2', () {
        expect(
          Query.query('users', postgresSqlDriver).orderByAsc('firstname').orderByAsc('lastname').statement,
          'SELECT * FROM users ORDER BY firstname ASC, lastname ASC;',
        );
      });

      test(' of level 3', () {
        expect(
          Query.query('users', postgresSqlDriver)
              .orderByAsc('firstname')
              .orderByDesc('lastname')
              .orderByAsc('age')
              .statement,
          'SELECT * FROM users ORDER BY firstname ASC, lastname DESC, age ASC;',
        );
      });
    });

    group('when `.orderByDesc`', () {
      test(' of level 1', () {
        expect(
          Query.query('users', postgresSqlDriver).orderByDesc('firstname').statement,
          'SELECT * FROM users ORDER BY firstname DESC;',
        );
      });

      test(' of level 2', () {
        expect(
          Query.query('users', postgresSqlDriver).orderByDesc('firstname').orderByDesc('lastname').statement,
          'SELECT * FROM users ORDER BY firstname DESC, lastname DESC;',
        );
      });

      test(' of level 3', () {
        expect(
          Query.query('users', postgresSqlDriver)
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
