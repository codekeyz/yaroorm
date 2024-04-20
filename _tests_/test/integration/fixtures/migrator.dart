import 'dart:io';

import 'package:test/test.dart';
import 'database.dart';

import 'package:yaroorm/src/cli/orm.dart';

void main(List<String> args) async {
  initializeORM();
  await OrmCLIRunner.start(args);
}

Future<void> runMigrator(String connectionName, String command) async {
  final commands = ['run', '_tests_/test/integration/fixtures/migrator.dart', command, '--connection=$connectionName'];
  print('> dart ${commands.join(' ')}\n');

  final result = await Process.run('dart', commands);
  stderr.write(result.stderr);

  expect(result.exitCode, 0);
}
