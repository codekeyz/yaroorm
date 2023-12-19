import 'package:yaroo/db/db.dart';
import 'package:yaroo/src/_config/config.dart';
import 'package:yaroorm/yaroorm.dart';

export 'package:yaroorm/src/database/migration.dart';

List<Schema> _accumulateSchemas(Function(List<Schema> schemas) func) {
  final result = <Schema>[];
  func(result);
  return result;
}

class Migrator {
  static const String migrate = 'migrate';
  static const String migrateReset = 'migrate:reset';

  static final migrationsSchema = Schema.create('migrations', ($table) {
    return $table
      ..id()
      ..string('migration')
      ..integer('batch');
  });

  static Future<void> processCmd(String cmd, ConfigResolver dbConfig, {List<String>? cmdArguments}) async {
    cmd = cmd.toLowerCase();

    final config = dbConfig.call();
    DB.init(() => config);

    final migrations = List<Migration>.from(config['migrations']);

    final resultingSchemas = <Schema>[];
    for (final migration in migrations) {
      final result = switch (cmd) {
        Migrator.migrate => _accumulateSchemas(migration.up),
        Migrator.migrateReset => _accumulateSchemas(migration.down),
        _ => throw UnsupportedError(cmd),
      };
      result.forEach((schema) => schema.scriptName = migration.name);
      resultingSchemas.addAll(result);
    }

    // if (!await (isMigrationsTableReady(driver))) {
    //   throw Exception('Unable to setup migrations table');
    // }

    print('------- Starting database migration --\n');

    // print('------- Starting database migration --\n');
    // for (final schema in resultingSchemas) {
    //   print('-x executing ${schema._scriptname}');
    //
    //   final script = schema.toScript(driver.blueprint);
    //   await driver.execute(script);
    // }
    // print('------- Completed migration  ✅ ------\n');
  }
}
