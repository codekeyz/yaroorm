import 'package:path/path.dart' as path;
import 'package:yaroorm/yaroorm.dart';

import 'migrations.dart';

part 'database.g.dart';

@DB.useConfig
final config = YaroormConfig(
  'foo_sqlite',
  connections: [
    DatabaseConnection(
      'foo_sqlite',
      DatabaseDriverType.sqlite,
      database: path.absolute('test/integration', 'db.sqlite'),
      dbForeignKeys: true,
    ),
    DatabaseConnection(
      'bar_mariadb',
      DatabaseDriverType.mariadb,
      database: 'test_db',
      host: 'localhost',
      username: 'tester',
      password: 'password',
      port: 3000,
    ),
    DatabaseConnection(
      'moo_mysql',
      DatabaseDriverType.mysql,
      database: 'test_db',
      host: 'localhost',
      username: 'tester',
      password: 'password',
      port: 3001,
      secure: true,
    ),
    DatabaseConnection(
      'foo_pgsql',
      DatabaseDriverType.pgsql,
      database: 'test_db',
      host: 'localhost',
      username: 'tester',
      password: 'password',
      port: 3002,
    ),
  ],
  migrations: [AddUsersTable(), AddPostsTable()],
);
