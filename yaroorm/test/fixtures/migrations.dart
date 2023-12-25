import 'package:yaroorm/src/database/migration.dart';

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
