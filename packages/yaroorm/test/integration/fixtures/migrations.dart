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

class AddPostsTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    final postSchema = Schema.create('posts', (table) {
      return table
        ..id()
        ..integer('userId')
        ..string('title')
        ..string('description')
        ..foreign<Post, User>(
            onKey: (key) => key.actions(
                onUpdate: ForeignKeyAction.cascade,
                onDelete: ForeignKeyAction.cascade))
        ..timestamps();
    });

    final postCommentSchema = Schema.create('post_comments', (table) {
      return table
        ..id(type: 'VARCHAR(255)', autoIncrement: false)
        ..integer('postId')
        ..string('comment')
        ..foreign<PostComment, Post>()
        ..timestamps();
    });

    schemas.addAll([postSchema, postCommentSchema]);
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists('post_comments'));

    schemas.add(Schema.dropIfExists('posts'));
  }
}
