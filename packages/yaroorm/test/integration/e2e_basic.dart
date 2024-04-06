import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import 'fixtures/migrator.dart';
import 'fixtures/test_data.dart';

void runBasicE2ETest(String connectionName) {
  final db = DB.connection(connectionName);

  return group('with ${db.driver.type.name} driver', () {
    test('driver should connect', () async {
      await db.driver.connect();

      expect(db.driver.isOpen, isTrue);
    });

    test('should have no tables',
        () async => expect(await db.driver.hasTable('users'), isFalse));

    test('should execute migration', () async {
      await runMigrator(connectionName, 'migrate');

      expect(await db.driver.hasTable('users'), isTrue);
    });

    test('should insert single user', () async {
      final result = await usersList.first.withDriver(db.driver).save();
      expect(result, isA<User>().having((p0) => p0.id, 'has primary key', 1));

      expect(await db.query<User>().all(), hasLength(1));
    });

    test('should insert many users', () async {
      final remainingUsers =
          usersList.sublist(1).map((e) => e.to_db_data).toList();
      final userQuery = db.query<User>();
      await userQuery.insertMany(remainingUsers);

      expect(await userQuery.all(), hasLength(usersList.length));
    });

    group('Aggregate Functions', () {
      final query = db.query<User>().isLike('home_address', '%%, Ghana');
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
              .contains(db.driver.type)) {
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
      final user = await db.query<User>().get();
      expect(user!.id!, 1);

      user
        ..firstname = 'Red Oil'
        ..age = 100;
      await user.save();

      final userFromDB = await db.query<User>().get(user.id!);
      expect(user, isNotNull);
      expect(userFromDB?.firstname, 'Red Oil');
      expect(userFromDB?.age, 100);
    });

    test('should update many users', () async {
      final userQuery = db.query<User>();

      final age50Users = userQuery.equal('age', 50);
      final usersWithAge50 = await age50Users.findMany();
      expect(usersWithAge50.length, 4);
      expect(usersWithAge50.every((e) => e.age == 50), isTrue);

      await userQuery.update(
          where: (query) => query.equal('age', 50),
          values: {'home_address': 'Keta, Ghana'}).execute();

      final updatedResult = await age50Users.findMany();
      expect(updatedResult.length, 4);
      expect(updatedResult.every((e) => e.age == 50), isTrue);
      expect(
          updatedResult.every((e) => e.homeAddress == 'Keta, Ghana'), isTrue);
    });

    test('should fetch only users in Ghana', () async {
      final query = db
          .query<User>()
          .isLike('home_address', '%, Ghana')
          .orderByDesc('age');
      final usersInGhana = await query.findMany();
      expect(usersInGhana.length, 10);
      expect(
        usersInGhana.every((e) => e.homeAddress.contains('Ghana')),
        isTrue,
      );

      expect(await query.take(4), hasLength(4));
    });

    test('should get all users between age 35 and 50', () async {
      final age50Users = await db
          .query<User>()
          .isBetween('age', [35, 50])
          .orderByDesc('age')
          .findMany();
      expect(age50Users.length, 19);
      expect(age50Users.first.age, 50);
      expect(age50Users.last.age, 35);
    });

    test('should get all users in somewhere in Nigeria', () async {
      final users = await db
          .query<User>()
          .isLike('home_address', '%, Nigeria')
          .orderByAsc('home_address')
          .findMany();

      expect(users.length, 18);
      expect(users.first.homeAddress, 'Abuja, Nigeria');
      expect(users.last.homeAddress, 'Owerri, Nigeria');
    });

    test('should get all users where age is 30 or 52', () async {
      final users = await db
          .query<User>()
          .equal('age', 30)
          .orWhere('age', '=', 52)
          .findMany();
      expect(users.every((e) => [30, 52].contains(e.age)), isTrue);
    });

    test('should delete user', () async {
      final userOne = await db.query<User>().get();
      expect(userOne, isNotNull);

      await userOne!.delete();

      final usersAfterDelete = await db.query<User>().all();
      expect(usersAfterDelete.any((e) => e.id == userOne.id), isFalse);
    });

    test('should delete many users', () async {
      final query = db.query<User>().isLike('home_address', '%, Nigeria');
      expect(await query.findMany(), isNotEmpty);

      await query.delete();

      expect(await query.findMany(), isEmpty);
    });

    test('should drop tables', () async {
      await runMigrator(connectionName, 'migrate:reset');

      expect(await db.driver.hasTable('users'), isFalse);
    });

    test('should disconnect', () async {
      expect(db.driver.isOpen, isTrue);

      await db.driver.disconnect();

      expect(db.driver.isOpen, isFalse);
    });
  });
}
