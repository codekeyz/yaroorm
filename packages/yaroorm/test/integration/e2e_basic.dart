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
      final result = await usersTestData.first.withDriver(db.driver).save();
      expect(result, isA<User>().having((p0) => p0.id, 'has primary key', 1));

      expect(await db.query<User>().all(), hasLength(1));
    });

    test('should insert many users', () async {
      final remainingUsers =
          usersTestData.sublist(1).map((e) => e.to_db_data).toList();
      final userQuery = db.query<User>();
      await userQuery.insertMany(remainingUsers);

      expect(await userQuery.all(), hasLength(usersTestData.length));
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

      final age50Users = userQuery.whereEqual('age', 50);
      final usersWithAge50 = await age50Users.findMany();
      expect(usersWithAge50.length, 4);
      expect(usersWithAge50.every((e) => e.age == 50), isTrue);

      await userQuery.update(
          where: (query) => query.whereEqual('age', 50),
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
          .whereLike('home_address', '%, Ghana')
          .orderByDesc('age');
      final usersInGhana = await query.findMany();
      expect(usersInGhana.length, 10);
      expect(
          usersInGhana.every((e) => e.homeAddress.contains('Ghana')), isTrue);

      expect(await query.take(4), hasLength(4));
    });

    test('should get all users between age 35 and 50', () async {
      final age50Users = await db
          .query<User>()
          .whereBetween('age', [35, 50])
          .orderByDesc('age')
          .findMany();
      expect(age50Users.length, 19);
      expect(age50Users.first.age, 50);
      expect(age50Users.last.age, 35);
    });

    test('should get all users in somewhere in Nigeria', () async {
      final users = await db
          .query<User>()
          .whereLike('home_address', '%, Nigeria')
          .orderByAsc('home_address')
          .findMany();

      expect(users.length, 18);
      expect(users.first.homeAddress, 'Abuja, Nigeria');
      expect(users.last.homeAddress, 'Owerri, Nigeria');
    });

    test('should get all users where age is 30 or 52', () async {
      final users = await db
          .query<User>()
          .whereEqual('age', 30)
          .orWhere('age', '=', 52)
          .findMany();
      expect(users.every((e) => [30, 52].contains(e.age)), isTrue);
    });

    group('aggregate function', () {
      test('sum', () async {
        final sum = await db.query<User>().sum('age');
        expect(sum, isA<num>());
        expect(sum, equals(1552));
      });

      test('count', () async {
        final count = await db.query<User>().count();
        expect(count, isA<int>());
        expect(count, equals(37));
      });

      test('average', () async {
        final average = await db.query<User>().average('age');
        expect(average, isA<num>());
        expect(average.toStringAsFixed(2), equals('41.95'));
      });

      test('max', () async {
        final max = await db.query<User>().max('age');
        expect(max, isA<num>());
        expect(max, equals(100));
      });

      test('min', () async {
        final min = await db.query<User>().min('age');
        expect(min, isA<num>());
        expect(min, equals(23));
      });

      test('concat', () async {
        final concat = await db.query<User>().concat('age', separator: '_');
        expect(concat, isA<String>());
        expect(concat, equals('home_address'));
      });

      test('should fetch Sum using a where clause', () async {
        final sum = await db
            .query<User>()
            .whereEqual('home_address', 'Accra, Ghana')
            .sum('age');
        expect(sum, isA<num>());
        expect(sum, equals(178));
      });

      test('should fetch Count', () async {
        final count = await db
            .query<User>()
            .whereEqual('home_address', 'Accra, Ghana')
            .count(field: 'id');
        expect(count, isA<int>());
        expect(count, equals(4));
      });

      test('should fetch Average using a where clause', () async {
        final average = await db
            .query<User>()
            .whereEqual('home_address', 'Accra, Ghana')
            .average('age');
        expect(average, isA<num>());
        expect(average, equals(double.parse('44.5')));
      });

      test('should fetch Max function using a where clause', () async {
        final max = await db
            .query<User>()
            .whereEqual('home_address', 'Accra, Ghana')
            .max('age');
        expect(max, isA<num>());
        expect(max, equals(100));
      });

      test('should fetch Min function using a where clause', () async {
        final min = await db
            .query<User>()
            .whereEqual('home_address', 'Accra, Ghana')
            .min('age');
        expect(min, isA<num>());
        expect(min, equals(25));
      });
    });

    test('should delete user', () async {
      final userOne = await db.query<User>().get();
      expect(userOne, isNotNull);

      await userOne!.delete();

      final usersAfterDelete = await db.query<User>().all();
      expect(usersAfterDelete.any((e) => e.id == userOne.id), isFalse);
    });

    test('should delete many users', () async {
      final query = db.query<User>().whereLike('home_address', '%, Nigeria');
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
