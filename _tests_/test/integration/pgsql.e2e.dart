import 'package:test/test.dart';
import 'fixtures/database.dart' as db;
import 'e2e_basic.dart';

void main() async {
  db.initializeORM();

  group('Postgres', () {
    group('Basic E2E Test', () => runBasicE2ETest('foo_pgsql'));

    // group('Relation E2E Test', () => runRelationsE2ETest('foo_pgsql'));
  });
}
