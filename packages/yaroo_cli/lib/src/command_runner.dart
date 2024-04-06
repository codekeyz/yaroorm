import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaroo_cli/src/commands/generate.dart';
import 'package:yaroo_cli/src/logger.dart';

const executableName = 'yaroo';
const packageName = 'yaroo_cli';
const description = 'The yaroo command-line tool';

class YarooCliCommandRunner extends CompletionCommandRunner<int> {
  YarooCliCommandRunner() : super(executableName, description) {
    argParser
      ..addFlag('version', negatable: false, help: 'Print the current version.')
      ..addFlag('verbose',
          abbr: 'v',
          help: 'Noisy logging, including all shell commands executed.',
          callback: (verbose) {
        if (verbose) logger.level = Level.verbose;
      });

    addCommand(GenerateEntityCommand());
  }

  @override
  void printUsage() => logger.info(usage);
}
