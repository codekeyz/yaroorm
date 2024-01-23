import 'package:test/test.dart';
import 'package:yaroorm/migration/cli.dart';
import 'package:yaroorm/yaroorm.dart';

import '../integration/fixtures/orm_config.dart' as db;

void main() {
  DB.init(db.config);

  group('Migration', () {
    group('CLI', () {
      test('should error when unsupported command', () {
        expect(() => MigratorCLI.processCmd('some-funky'), throwsUnsupportedError);
      });

      test('should error when connection not found', () async {
        late Object error;

        try {
          await MigratorCLI.processCmd('migrate', cmdArguments: ['--database=my_new_db']);
        } catch (e) {
          error = e;
        }

        expect(
          error,
          isA<ArgumentError>()
              .having((p0) => p0.message, 'message', 'No database connection found with name: my_new_db'),
        );
      });
    });
  });
}
