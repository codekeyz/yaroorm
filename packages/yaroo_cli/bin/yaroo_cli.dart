import 'package:yaroo_cli/src/command_runner.dart';
import 'package:yaroo_cli/src/utils.dart';

void main(List<String> args) async {
  await flushThenExit(await YarooCliCommandRunner().run(args) ?? 0);
}
