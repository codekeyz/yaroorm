import 'package:path/path.dart' as path;
import 'package:yaroorm/yaroorm.dart';

final sqliteConnection = DatabaseConnection(
  'db',
  path.absolute('test/integration', 'db.sqlite'),
  DatabaseDriverType.sqlite,
);

const _baseConfig = {
  'database': 'test_db',
  'host': 'localhost',
  'port': 3000,
  'username': 'root',
  'password': 'password',
};

final mariadbConnection = DatabaseConnection.from('mariadb', {'driver': 'mariadb', ..._baseConfig});

final mysqlConnection = DatabaseConnection.from('mysql', {'driver': 'mysql', ..._baseConfig});
