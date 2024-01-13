import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/migrator.dart';
import '../fixtures/test_data.dart';

void runRelationsE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  return group('with ${driver.type.name} driver', () {
    User? testUser;

    setUpAll(() async {
      await driver.connect();

      expect(driver.isOpen, isTrue);

      var hasTables = await Future.wait([driver.hasTable('users'), driver.hasTable('todos')]);
      expect(hasTables.every((e) => e), isFalse);

      await runMigrator(connectionName, 'migrate');

      hasTables = await Future.wait([driver.hasTable('users'), driver.hasTable('todos')]);
      expect(hasTables.every((e) => e), isTrue);

      testUser = await usersTestData.first.withDriver(driver).save();
      expect(testUser, isA<User>().having((p0) => p0.id, 'has primary key', 1));
    });

    test('should insert todo for User', () async {
      final result = await testUser!.todo.set(Todo('Foo Bar', 'mee moo grand maa'));
      expect(result.id, isNotNull);
      expect(result.userId, testUser!.id!);
      expect(result.createdAt, isNotNull);
      expect(result.updatedAt, isNotNull);

      final todosFromDb = await testUser!.todos.get();
      expect(todosFromDb, hasLength(1));
      expect(todosFromDb.map((e) => e.title), ['Foo Bar']);
    });

    test('should delete todo when User deleted ', () async {
      final todosQuery = Query.table<Todo>().driver(driver).whereEqual('userId', testUser!.id!);

      var userTodos = await todosQuery.findMany();
      expect(userTodos, isNotEmpty);

      await testUser!.delete();

      final user = await Query.table<User>().driver(driver).get(testUser!.id!);
      expect(user, isNull);

      userTodos = await todosQuery.findMany();
      expect(userTodos, isEmpty);
    });

    tearDownAll(() async {
      await runMigrator(connectionName, 'migrate:reset');

      final hasTables = await Future.wait([driver.hasTable('users'), driver.hasTable('todos')]);
      expect(hasTables.every((e) => e), isFalse);

      await driver.disconnect();
      expect(driver.isOpen, isFalse);
    });
  });
}
