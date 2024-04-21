import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm_tests/src/models.dart';

class AddPostsTable extends Migration {
  @override
  void up(List<Schema> schemas) {
    schemas.addAll([PostSchema, PostCommentSchema]);
  }

  @override
  void down(List<Schema> schemas) {
    schemas.add(Schema.dropIfExists(PostCommentSchema));

    schemas.add(Schema.dropIfExists(PostSchema));
  }
}
