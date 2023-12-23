import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';
import 'package:yaroorm/src/database/migration.dart';
import 'package:yaroorm/src/query/query.dart';

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

const usersList = [
  {'firstname': 'Chima', 'lastname': 'Precious', 'age': 22, 'home_address': 'Lagos, Nigeria'},
  {'firstname': 'Pookie', 'lastname': 'Rey-Rey', 'age': 30, 'home_address': 'Los Angeles'},
  {'firstname': 'Johnson', 'lastname': 'Python', 'age': 40, 'home_address': 'Argentina'},
  {'firstname': 'MaxWell', 'lastname': 'Luther', 'age': 35, 'home_address': 'Mexico'},
];

void runIntegrationTest(DatabaseDriver driver) {
  return group('Integration Test with ${driver.type.name}', () {
    test('driver should connect', () async {
      await driver.connect();

      expect(driver.isOpen, isTrue);
    });

    test('should execute migrations', () async {
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

      final hasUsersTable = await driver.hasTable('users');
      expect(hasUsersTable, isTrue);

      final hasTodosTable = await driver.hasTable('tasks');
      expect(hasTodosTable, isTrue);
    });

    group('Integration with ${driver.type.name}', () {
      test('should add users', () async {
        final result = await Query.table('users').driver(driver).insert(usersList.first).exec();
        expect(result, 1);
      });

      test('should add many users', () async {
        await Query.table('users').driver(driver).insertAll(usersList.sublist(1)).exec();

        final users = await Query.table('users').driver(driver).all();
        expect(users, usersList.map((e) => {...e, 'id': usersList.indexOf(e) + 1}).toList());
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
    });
  });
}
