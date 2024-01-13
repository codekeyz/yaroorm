import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/migrator.dart';
import '../fixtures/test_data.dart';

void runRelationsE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  return group('with ${driver.type.name} driver', () {
    User? currentUser;

    setUpAll(() async {
      await driver.connect();

      expect(driver.isOpen, isTrue);

      var hasTables = await Future.wait([driver.hasTable('users'), driver.hasTable('todos')]);
      expect(hasTables.every((e) => e), isFalse);

      await runMigrator(connectionName, 'migrate');

      hasTables = await Future.wait([driver.hasTable('users'), driver.hasTable('todos')]);
      expect(hasTables.every((e) => e), isTrue);

      currentUser = await usersTestData.first.withDriver(driver).save();
      expect(currentUser, isA<User>().having((p0) => p0.id, 'has primary key', 1));
    });

    test('should insert todo for User', () async {
      final userId = currentUser!.id!;

      final todo = await Todo('Foo Bar', 'mee moo grand maa', userId: userId).withDriver(driver).save();
      expect(todo.id, isNotNull);
      expect(todo.createdAt, isNotNull);
      expect(todo.updatedAt, isNotNull);

      final todoFromDB = await currentUser!.todo.get();
      expect(todoFromDB, isNotNull);
      expect(todoFromDB!.id, todo.id!);
      expect(todoFromDB.userId, userId);
      expect(todoFromDB.completed, false);

      await Todo('Dart for Backend', 'let us celebrate now today', userId: userId).withDriver(driver).save();

      final todosFromDb = await currentUser!.todos.get();
      expect(todosFromDb, hasLength(2));
      expect(todosFromDb.map((e) => e.title), ['Foo Bar', 'Dart for Backend']);
    });

    test('should delete todo when User deleted ', () async {
      final todosQuery = Query.table<Todo>().driver(driver).whereEqual('userId', currentUser!.id!);

      var userTodos = await todosQuery.findMany();
      expect(userTodos, isNotEmpty);

      await currentUser!.delete();

      final user = await Query.table<User>().driver(driver).get(currentUser!.id!);
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
