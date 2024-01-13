import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/migrator.dart';
import '../fixtures/test_data.dart';

void runBasicE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  return group('with ${driver.type.name} driver', () {
    test('driver should connect', () async {
      await driver.connect();

      expect(driver.isOpen, isTrue);
    });

    test('should have no tables', () async {
      final result = await Future.wait([
        driver.hasTable('users'),
        driver.hasTable('todos'),
      ]);

      expect(result.every((e) => e), isFalse);
    });

    test('should execute migration', () async {
      await runMigrator(connectionName, 'migrate');

      final result = await Future.wait([
        driver.hasTable('users'),
        driver.hasTable('todos'),
      ]);

      expect(result.every((e) => e), isTrue);
    });

    test('should insert single user', () async {
      final result = await usersTestData.first.withDriver(driver).save();
      expect(result, isA<User>().having((p0) => p0.id, 'has primary key', 1));

      final users = await Query.table<User>().driver(driver).all();
      expect(users.length, 1);
    });

    test('should insert many users', () async {
      final remainingUsers = usersTestData.sublist(1).map((e) => e.to_db_data).toList();
      final userQuery = Query.table<User>().driver(driver);
      await userQuery.insertMany(remainingUsers);

      final users = await userQuery.all();

      expect(users.length, usersTestData.length);
    });

    test('should update user', () async {
      final userQuery = Query.table<User>().driver(driver);

      var user = (await userQuery.get());
      final userId = user!.id!;
      expect(userId, 1);

      await userQuery.update(where: (where) => where.whereEqual('id', userId), values: {'firstname': 'Red Oil'}).exec();

      user = await userQuery.get(userId);
      expect(user, isNotNull);

      user as User;
      expect(user.firstname, 'Red Oil');
      expect(user.id, 1);
    });

    test('should update many users', () async {
      final userQuery = Query.table<User>().driver(driver);

      final age50Users = userQuery.whereEqual('age', 50);
      final usersWithAge50 = await age50Users.findMany();
      expect(usersWithAge50.length, 4);
      expect(usersWithAge50.every((e) => e.age == 50), isTrue);

      await userQuery
          .update(where: (query) => query.whereEqual('age', 50), values: {'home_address': 'Keta, Ghana'}).exec();

      final updatedResult = await age50Users.findMany();
      expect(updatedResult.length, 4);
      expect(updatedResult.every((e) => e.age == 50), isTrue);
      expect(updatedResult.every((e) => e.homeAddress == 'Keta, Ghana'), isTrue);
    });

    test('should fetch only users in Ghana', () async {
      final userQuery = Query.table<User>().driver(driver);

      final query = userQuery.whereLike('home_address', '%, Ghana').orderByDesc('age');
      final usersInGhana = await query.findMany();
      expect(usersInGhana.length, 10);
      expect(usersInGhana.every((e) => e.homeAddress.contains('Ghana')), isTrue);

      final take4 = await query.take(4);
      expect(take4.length, 4);
    });

    test('should get all users between age 35 and 50', () async {
      final userQuery = Query.table<User>().driver(driver);

      final age50Users = await userQuery.whereBetween('age', [35, 50]).orderByDesc('age').findMany();
      expect(age50Users.length, 19);
      expect(age50Users.first.age, 50);
      expect(age50Users.last.age, 35);
    });

    test('should get all users in somewhere in Nigeria', () async {
      final userQuery = Query.table<User>().driver(driver);

      final users = await userQuery.whereLike('home_address', '%, Nigeria').orderByAsc('home_address').findMany();

      expect(users.length, 18);
      expect(users.first.homeAddress, 'Abuja, Nigeria');
      expect(users.last.homeAddress, 'Owerri, Nigeria');
    });

    test('should get all users where age is 30 or 52', () async {
      final userQuery = Query.table<User>().driver(driver);

      final users = await userQuery.whereEqual('age', 30).orWhere('age', '=', 52).findMany();
      expect(users.every((e) => [30, 52].contains(e.age)), isTrue);
    });

    test('should delete user', () async {
      final userQuery = Query.table<User>().driver(driver);

      final userOne = await userQuery.get();
      expect(userOne, isNotNull);

      await userOne!.delete();

      final usersAfterDelete = await userQuery.all();
      expect(usersAfterDelete.any((e) => e.id == userOne.id), isFalse);
    });

    test('should delete many users', () async {
      final userQuery = Query.table<User>().driver(driver);

      final query = userQuery.whereLike('home_address', '%, Nigeria');

      final users = await query.findMany();
      expect(users, isNotEmpty);

      await query.delete();

      final usersAfterDelete = await query.findMany();
      expect(usersAfterDelete, isEmpty);
    });

    test('should drop tables', () async {
      await runMigrator(connectionName, 'migrate:reset');

      final result = await Future.wait([driver.hasTable('users'), driver.hasTable('todos')]);

      expect(result.every((e) => e), isFalse);
    });

    test('should disconnect', () async {
      expect(driver.isOpen, isTrue);

      await driver.disconnect();

      expect(driver.isOpen, isFalse);
    });
  });
}
