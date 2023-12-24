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
  'username': 'root',
  'password': 'password',
};

final mariadbConnection = DatabaseConnection.from('mariadb', {'driver': 'mariadb', 'port': 3000, ..._baseConfig});

final mysqlConnection = DatabaseConnection.from('mysql', {'driver': 'mysql', 'port': 3001, ..._baseConfig});
