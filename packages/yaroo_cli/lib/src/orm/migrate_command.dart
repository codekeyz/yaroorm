import 'dart:async';

import 'package:args/command_runner.dart';

class MigrateCommand extends Command<int> {
  @override
  String get description => 'migrate your database';

  @override
  String get name => 'migrate';

  @override
  FutureOr<int> run() async {
    print('Say hello');

    return 0;
  }
}
