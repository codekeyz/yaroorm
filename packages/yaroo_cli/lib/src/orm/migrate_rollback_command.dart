import 'dart:async';

import 'package:args/command_runner.dart';

class MigrationRollbackCommand extends Command<int> {
  @override
  String get description => 'rollback last migration batch';

  @override
  String get name => 'migrate:rollback';

  @override
  FutureOr<int> run() async {
    return 0;
  }
}
