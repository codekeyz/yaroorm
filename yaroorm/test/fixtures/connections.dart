import 'package:path/path.dart' as path;
import 'package:yaroorm/yaroorm.dart';

final sqliteConnection = DatabaseConnection(
  'db',
  path.absolute('test/integration', 'db.sqlite'),
  DatabaseDriverType.sqlite,
);

final mariadbConnection = DatabaseConnection.from('maria_connection', {
  'database': 'test_db',
  'driver': 'mariadb',
  'host': 'localhost',
  'port': 3000,
  'username': 'root',
  'password': 'password',
});

final mysqlConnection = DatabaseConnection.from('mysql_connection', {
  'database': 'test_db',
  'driver': 'mysql',
  'host': 'localhost',
  'port': 3001,
  'username': 'root',
  'password': 'password',
});
