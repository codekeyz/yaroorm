import 'package:yaroorm/migration.dart';

import 'test_data.dart';

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

    schemas.add(userSchema);
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists('users'));
  }
}

class AddTodosTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    final schema = Schema.create('todos', (table) {
      return table
        ..id()
        ..integer('ownerId')
        ..string('title')
        ..string('description')
        ..boolean('completed', defaultValue: false)
        ..foreign<Todo, User>(
          'ownerId',
          onKey: (key) => key.actions(onUpdate: ForeignKeyAction.cascade, onDelete: ForeignKeyAction.cascade),
        )
        ..timestamps();
    });

    schemas.add(schema);
  }

  @override
  void down(List<Schema> schemas) => schemas.add(Schema.dropIfExists('todos'));
}
