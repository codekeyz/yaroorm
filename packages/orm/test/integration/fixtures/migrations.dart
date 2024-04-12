import 'package:yaroorm/src/migration.dart';

import 'models.dart';

class AddUsersTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    schemas.add(UserSchema);
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists(UserSchema));
  }
}

class AddPostsTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    final postSchema = PostSchema;

    schemas.addAll([postSchema, PostCommentSchema]);
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists(PostCommentSchema));

    schemas.add(Schema.dropIfExists(PostSchema));
  }
}
