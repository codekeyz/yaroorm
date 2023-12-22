import 'package:yaroorm/yaroorm.dart';

final sqliteConnection = DatabaseConnection(
  'db',
  'sqlite',
  DatabaseDriverType.sqlite,
);

final mysqlConnection = DatabaseConnection.from('maria_connection', {
  'database': 'mysql_test_db',
  'driver': 'mysql',
  'host': 'localhost',
});

final mariadbConnection = DatabaseConnection.from('maria_connection', {
  'database': 'maria_test_db',
  'driver': 'mariadb',
  'host': 'localhost',
});
