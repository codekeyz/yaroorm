import 'package:yaroorm/yaroorm.dart';
import 'package:yaroorm_test/src/models.dart';

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
