import 'package:yaroorm/migration.dart';
import 'package:yaroorm/src/database/driver/sqlite_driver.dart';

import 'test_data.dart';
import 'migrations.reflectable.dart';

class AddUsersTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    schemas.add(Schema.fromEntity(User));
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists(User));
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

    schemas.add(Schema.dropIfExists(Post));
  }
}
