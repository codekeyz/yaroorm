import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/database/migration.dart';
import 'package:yaroorm/src/query/query.dart';

import '../fixtures/test_data.dart';

class AddUsersTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    final userSchema = Schema.create('users', (table) {
      return table
        ..id()
        ..string('firstname')
        ..string('lastname')
        ..integer('age')
        ..string('home_address');
    });

    final taskSchema = Schema.create('tasks', (table) {
      return table
        ..id()
        ..string('title')
        ..string('description')
        ..boolean('completed', defaultValue: false)
        ..integer('user_id');
    });

    schemas.addAll([userSchema, taskSchema]);
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists('users'));
    schemas.add(Schema.dropIfExists('tasks'));
  }
}

void runIntegrationTest(DatabaseDriver driver) {
  return group('Integration Test with ${driver.type.name} driver', () {
    setUpAll(() async {
      final schemas = <Schema>[];
      AddUsersTable().down(schemas);

      final dropTableScripts = schemas.map((schema) => schema.toScript(driver.blueprint)).join('\n');

      await driver.execute(dropTableScripts);
    });

    test('should have no tables', () async {
      final result = await Future.wait([
        driver.hasTable('users'),
        driver.hasTable('tasks'),
      ]);

      expect(result.every((e) => e), isFalse);
    });

    test('should execute migration', () async {
      final schemas = <Schema>[];
      AddUsersTable().up(schemas);

      final createTableScripts = schemas.map((schema) => schema.toScript(driver.blueprint));

      await driver.transaction((transactor) async {
        for (final script in createTableScripts) {
          await transactor.execute(script);
        }

        if (driver.type == DatabaseDriverType.sqlite) {
          await transactor.commit();
        }
      });

      final result = await Future.wait([
        driver.hasTable('users'),
        driver.hasTable('tasks'),
      ]);

      expect(result.every((e) => e), isTrue);
    });

    test('should insert users', () async {
      final result = await Query.table('users').driver(driver).insert(usersTestData.first).exec();
      expect(result, 1);

      final users = await Query.table('users').driver(driver).all();
      expect(users.length, 1);
    });

    test('should insert many users', () async {
      await Query.table('users').driver(driver).insertAll(usersTestData.sublist(1)).exec();

      final users = await Query.table('users').driver(driver).all();
      expect(users, usersTestData.map((e) => {...e, 'id': usersTestData.indexOf(e) + 1}).toList());
    });

    test('should update user', () async {
      var user = await Query.table('users').driver(driver).get();
      expect(user, isNotNull);
      final userId = user!['id'];
      expect(userId, 1);

      await Query.table('users')
          .driver(driver)
          .update(where: (where) => where.where('id', '=', userId), values: {'firstname': 'Red Oil'}).exec();

      user = await Query.table('users').driver(driver).where('id', '=', userId).findOne();
      expect(user, isNotNull);
      expect(user!['firstname'], 'Red Oil');
      expect(user!['id'], 1);
    });

    test('should update many users', () async {
      final age50Users = Query.table('users').driver(driver).where('age', '=', 50);
      final usersWithAge50 = await age50Users.findMany();
      expect(usersWithAge50.length, 4);
      expect(usersWithAge50.every((e) => e['age'] == 50), isTrue);

      final updateQuery = Query.table('users')
          .driver(driver)
          .update(where: (where) => where.where('age', '=', 50), values: {'home_address': 'Keta Lagoon'});

      await updateQuery.exec();

      final updatedResult = await age50Users.findMany();
      expect(updatedResult.length, 4);
      expect(updatedResult.every((e) => e['age'] == 50), isTrue);
      expect(updatedResult.every((e) => e['home_address'] == 'Keta Lagoon'), isTrue);
    });

    test('should get all users between age 35 and 50', () async {
      final age50Users =
          await Query.table('users').driver(driver).whereBetween('age', [35, 50]).orderByDesc('age').findMany();
      expect(age50Users.length, 19);
      expect(age50Users.first['age'], 50);
      expect(age50Users.last['age'], 35);
    });

    test('should get all users in somewhere in Nigeria', () async {
      final users = await Query.table('users')
          .driver(driver)
          .whereLike('home_address', '%, Nigeria')
          .orderByAsc('home_address')
          .findMany();

      expect(users.length, 33);
      expect(users.first['home_address'], 'Abuja, Nigeria');
      expect(users.last['home_address'], 'Owerri, Nigeria');
    });

    test('should get all users where age is 30 or 52', () async {
      final users = await Query.table('users').driver(driver).where('age', '=', 30).orWhere('age', '=', 52).findMany();
      expect(users.every((e) => [30, 52].contains(e['age'])), isTrue);
    });

    test('should delete user', () async {
      final query = Query.table('users').driver(driver);

      final userOne = await query.get();
      expect(userOne, isNotNull);

      await query.delete((builder) => builder.where('id', '=', userOne['id'])).exec();

      final usersAfterDelete = await query.all();
      expect(usersAfterDelete.any((e) => e['id'] == userOne['id']), isFalse);
    });

    test('should delete many users', () async {
      final query = Query.table('users').driver(driver).whereIn('home_address', ['Lagos, Nigeria']);

      final users = await query.findMany();
      expect(users, isNotEmpty);

      await query.delete();

      final usersAfterDelete = await query.findMany();
      expect(usersAfterDelete, isEmpty);
    });

    test('should drop tables', () async {
      final schemas = <Schema>[];
      AddUsersTable().down(schemas);

      final dropTableScripts = schemas.map((schema) => schema.toScript(driver.blueprint)).join('\n');

      await driver.execute(dropTableScripts);

      final hasUsersTable = await driver.hasTable('users');
      expect(hasUsersTable, isFalse);

      final hasTodosTable = await driver.hasTable('tasks');
      expect(hasTodosTable, isFalse);
    });

    test('should disconnect', () async {
      expect(driver.isOpen, isTrue);

      await driver.disconnect();

      expect(driver.isOpen, isFalse);
    });
  });
}
