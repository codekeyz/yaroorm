import 'package:path/path.dart' as path;
import 'package:yaroorm/config.dart';

import 'migrations.dart';

const _baseConfig = {
  'database': 'test_db',
  'host': 'localhost',
  'username': 'root',
  'password': 'password',
};

final config = YaroormConfig.from({
  'default': 'foo_sqlite',
  'connections': {
    'foo_sqlite': {
      'driver': 'sqlite',
      'database': path.absolute('test/integration', 'db.sqlite'),
      'foreign_key_constraints': true,
    },
    'bar_mariadb': {
      'driver': 'mariadb',
      'port': 3000,
      ..._baseConfig,
    },
    'moo_mysql': {
      'driver': 'mysql',
      'port': 3001,
      ..._baseConfig,
    },
    'foo_pgsql': {
      'driver': 'pgsql',
      'port': 5432,
      'database': 'postgres',
      'host': 'localhost',
      'username': 'postgres',
      'password': 'password',
    },
  },
  'migrations_table': 'migrations',
  'migrations': [AddUsersTable()]
});
