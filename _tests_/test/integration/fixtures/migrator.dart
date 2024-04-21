import 'dart:io';

import 'package:test/test.dart';

Future<void> runMigrator(String connectionName, String command) async {
  final commands = ['run', 'yaroorm', command, '--connection=$connectionName'];
  print('> dart ${commands.join(' ')}\n');

  final result = await Process.run('dart', commands);
  stderr.write(result.stderr);

  expect(result.exitCode, 0);
}
