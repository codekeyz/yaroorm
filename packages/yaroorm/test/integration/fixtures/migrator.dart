import 'dart:io';

import 'package:test/test.dart';
import 'package:yaroo_cli/orm/orm.dart';
import '../fixtures/orm_config.dart' as conf;
import 'migrator.reflectable.dart';

void main(List<String> args) async {
  initializeReflectable();
  await OrmCLIRunner.start(args, conf.config);
}

Future<void> runMigrator(String connectionName, String command) async {
  final commands = [
    'run',
    'test/integration/fixtures/migrator.dart',
    command,
    '--connection=$connectionName'
  ];
  print('> dart ${commands.join(' ')}\n');

  final result = await Process.run('dart', commands);
  stderr.write(result.stderr);

  expect(result.exitCode, 0);
}
