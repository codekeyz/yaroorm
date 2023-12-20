import 'package:yaroorm/yaroorm.dart';

final sqliteConnection = DatabaseConnection(
  'db',
  'sqlite',
  DatabaseDriverType.sqlite,
);

final postgresSqlConnection = DatabaseConnection(
  'db',
  'pgsql',
  DatabaseDriverType.pgsql,
);
