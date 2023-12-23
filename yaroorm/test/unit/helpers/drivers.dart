import 'package:path/path.dart' as path;
import 'package:yaroorm/yaroorm.dart';

final sqliteConnection = DatabaseConnection(
  'db',
  path.absolute('test/integration', 'db.sqlite'),
  DatabaseDriverType.sqlite,
);

final mysqlConnection = DatabaseConnection.from('maria_connection', {
  'database': 'mysql_test_db',
  'driver': 'mysql',
  'host': 'localhost',
  'username': 'foo-bar',
  'password': 'sassy',
});

final mariadbConnection = DatabaseConnection.from('maria_connection', {
  'database': 'maria_test_db',
  'driver': 'mariadb',
  'host': 'localhost',
  'username': 'runner',
  'password': 'password',
});

final postGresConnection = DatabaseConnection.from('postgres_connection', {
  'database': 'postgres_db',
  'driver': 'pgsql',
  'host': 'localhost',
  'username': 'runner',
  'password': 'password',
});
