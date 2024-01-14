import 'package:path/path.dart' as path;
import 'package:yaroorm/config.dart';
import 'package:yaroorm/yaroorm.dart';

import 'migrations.dart';

final config = YaroormConfig(
  'foo_sqlite',
  connections: [
    DatabaseConnection('foo_sqlite', path.absolute('test/integration', 'db.sqlite'), DatabaseDriverType.sqlite,
        dbForeignKeys: true),
    DatabaseConnection('bar_mariadb', 'test_db', DatabaseDriverType.mariadb,
        host: 'localhost', username: 'root', password: 'password', port: 3000),
    DatabaseConnection('moo_mysql', 'test_db', DatabaseDriverType.mysql,
        host: 'localhost', username: 'root', password: 'password', port: 3001, secure: true),
    DatabaseConnection('foo_pgsql', 'test_db', DatabaseDriverType.mysql,
        host: 'localhost', username: 'root', password: 'password', port: 3002),
  ],
  migrationsTable: 'migrations',
  migrations: [AddUsersTable(), AddPostsTable()],
);
