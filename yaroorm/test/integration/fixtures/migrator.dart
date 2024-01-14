import 'dart:io';

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:yaroorm/migration/cli.dart';
import 'package:yaroorm/yaroorm.dart';

import '../fixtures/orm_config.dart' as conf;

import 'migrator.reflectable.dart';

void main(List<String> args) async {
  if (args.isEmpty) throw UnsupportedError('Provide args');

  initializeReflectable();

  DB.init(conf.config);

  await MigratorCLI.processCmd(args[0], cmdArguments: args.sublist(1));
}

@visibleForTesting
Future<void> runMigrator(String connectionName, String command) async {
  final commands = ['run', 'test/integration/fixtures/migrator.dart', command, '--database=$connectionName'];
  print('> dart ${commands.join(' ')}\n');

  final result = await Process.run('dart', commands);
  stderr.write(result.stderr);
  expect(result.exitCode, 0);
}
