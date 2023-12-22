import 'package:yaroorm/yaroorm.dart';

final sqliteConnection = DatabaseConnection(
  'db',
  'sqlite',
  DatabaseDriverType.sqlite,
);

final mysqlConnection = DatabaseConnection(
  'db',
  'sqlite',
  DatabaseDriverType.mysql,
);
