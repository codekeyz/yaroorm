import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaroo_cli/src/type_analyzer.dart';

class GenerateEntityCommand extends Command<int> {
  @override
  String get description => 'Generate entity related code';

  @override
  String get name => 'generate';

  @override
  Future<int> run() async {
    await EntityAnalyzer(Directory.current).analyze();
    return 0;
  }
}
