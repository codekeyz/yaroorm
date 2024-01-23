import 'dart:async';

import 'package:args/command_runner.dart';

class MigrationResetCommand extends Command<int> {
  @override
  String get description => 'reset database migrations';

  @override
  String get name => 'migrate:reset';

  @override
  FutureOr<int> run() async {
    return 0;
  }
}
