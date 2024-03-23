# Yaroorm 📦

Yaroorm makes it easy to interact with databases. Currently, it provides official support for the following four databases:

- SQLite
- MariaDB
- MySQL
- PostgreSQL

## Installation

To get started, add `yaroorm` as a dependency and build_runner as a dev dependency:

```dart

dart pub add yaroorm


```


## CONNECTING TO THE DATABASE

- Establishing the connection

```dart

final db = DB.connection('test_db');
await db.driver.connect();

```

The supported database drivers for 'yaroorm' are:

- Supported database drivers:
- SQLite
- MariaDB
- MySQL
- PostgreSQL





Find the quickstart & documentation here: https://docs.yaroo.dev/orm/quickstart
