import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm_tests/src/models.dart';

import '../../lib/test_data.dart';
import '../util.dart';

void runBasicE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  return group('with ${driver.type.name} driver', () {
    test('driver should connect', () async {
      await driver.connect();

      expect(driver.isOpen, isTrue);
    });

    test('should have no tables',
        () async => expect(await driver.hasTable('users'), isFalse));

    test('should execute migration', () async {
      await runMigrator(connectionName, 'migrate');

      expect(await driver.hasTable('users'), isTrue);
    });

    test('should insert single user', () async {
      final firstData = usersList.first;
      final query = UserQuery.driver(driver);
      final result = await query.create(
        firstname: firstData.firstname,
        lastname: firstData.lastname,
        age: firstData.age,
        homeAddress: firstData.homeAddress,
      );

      final exists = await query.where((user) => user.id(result.id)).exists();
      expect(exists, isTrue);
    });

    test('should insert many users', () async {
      final query = UserQuery.driver(driver);

      for (final user in usersList.skip(1)) {
        await query.create(
          firstname: user.firstname,
          lastname: user.lastname,
          age: user.age,
          homeAddress: user.homeAddress,
        );
      }

      expect(await query.count(), usersList.length);
    });

    group('Aggregate Functions', () {
      final query = UserQuery.driver(driver)
          .where((user) => user.$isLike('home_address', '%%, Ghana'));
      List<User> usersInGhana = [];

      setUpAll(() async {
        usersInGhana = await query.findMany();
        expect(usersInGhana, isNotEmpty);
      });

      test('sum', () async {
        final manualSum = usersInGhana.map((e) => e.age).sum;
        expect(await query.sum('age'), equals(manualSum));
      });

      test('count', () async {
        expect(await query.count(), equals(usersInGhana.length));
      });

      test('max', () async {
        final maxAge = usersInGhana.map((e) => e.age).max;
        expect(await query.max('age'), equals(maxAge));
      });

      test('min', () async {
        final minAge = usersInGhana.map((e) => e.age).min;
        expect(await query.min('age'), equals(minAge));
      });

      test('average', () async {
        final average = usersInGhana.map((e) => e.age).average;
        expect(await query.average('age'), equals(average));
      });

      test('concat', () async {
        Matcher matcher(String separator) {
          if ([DatabaseDriverType.sqlite, DatabaseDriverType.pgsql]
              .contains(driver.type)) {
            return equals(usersInGhana.map((e) => e.age).join(separator));
          }

          return equals(
            usersInGhana.map((e) => '${e.age}$separator').join(','),
          );
        }

        expect(await query.groupConcat('age', ','), matcher(','));
      });
    });

    test('should update user', () async {
      final query = UserQuery.driver(driver).where((user) => user.id(1));

      final user = await query.findOne();
      expect(user!.id, 1);

      await query.update(firstname: value('Red Oil'), age: value(100));

      final userFromDB = await query.findOne();
      expect(user, isNotNull);
      expect(userFromDB?.firstname, 'Red Oil');
      expect(userFromDB?.age, 100);
    });

    test('should update many users', () async {
      final userQuery = UserQuery.driver(driver);
      final age50Users = userQuery.where((user) => user.age(50));

      final usersWithAge50 = await age50Users.findMany();
      expect(usersWithAge50.length, 4);
      expect(usersWithAge50.every((e) => e.age == 50), isTrue);

      await age50Users.update(homeAddress: value('Keta, Ghana'));

      final updatedResult = await age50Users.findMany();
      expect(updatedResult.length, 4);
      expect(updatedResult.every((e) => e.age == 50), isTrue);
      expect(
          updatedResult.every((e) => e.homeAddress == 'Keta, Ghana'), isTrue);
    });

    test('should fetch only users in Ghana', () async {
      final userQuery = UserQuery.driver(driver)
          .where((user) => user.$isLike('home_address', '%, Ghana'));

      final usersInGhana = await userQuery.findMany();
      expect(usersInGhana.length, 10);
      expect(
        usersInGhana.every((e) => e.homeAddress.contains('Ghana')),
        isTrue,
      );

      expect(await userQuery.findMany(limit: 4), hasLength(4));
    });

    test('should get all users between age 35 and 50', () async {
      final age50Users = await UserQuery.driver(driver)
          .where((user) => user.$isBetween('age', [35, 50]))
          .findMany(orderBy: [OrderUserBy.age(OrderDirection.desc)]);

      expect(age50Users.length, 19);
      expect(age50Users.first.age, 50);
      expect(age50Users.last.age, 35);
    });

    test('should get all users in somewhere in Nigeria', () async {
      final users = await UserQuery.driver(driver)
          .where((user) => user.$isLike('home_address', '%, Nigeria'))
          .findMany(orderBy: [OrderUserBy.homeAddress(OrderDirection.asc)]);

      expect(users.length, 18);
      expect(users.first.homeAddress, 'Abuja, Nigeria');
      expect(users.last.homeAddress, 'Owerri, Nigeria');
    });

    test('should get all users where age is 30 or 52', () async {
      final users = await UserQuery.driver(driver)
          .where((user) => user.or([
                user.age(30),
                user.age(52),
              ]))
          .findMany();

      expect(users.every((e) => [30, 52].contains(e.age)), isTrue);
    });

    test('should delete user', () async {
      final userQuery = UserQuery.driver(driver);
      final userOne = await userQuery.findOne();
      expect(userOne, isNotNull);

      final userOneQuery = userQuery.where((user) => user.id(userOne!.id));

      await userOneQuery.delete();

      expect(await userOneQuery.findOne(), isNull);
    });

    test('should delete many users', () async {
      final query = UserQuery.driver(driver)
          .where((user) => user.$isLike('home_address', '%, Nigeria'));
      expect(await query.findMany(), isNotEmpty);

      await query.delete();

      expect(await query.findMany(), isEmpty);
    });

    test('should drop tables', () async {
      await runMigrator(connectionName, 'migrate:reset');

      expect(await driver.hasTable('users'), isFalse);
    });

    test('should disconnect', () async {
      expect(driver.isOpen, isTrue);

      await driver.disconnect();

      expect(driver.isOpen, isFalse);
    });
  });
}
