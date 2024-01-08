import 'package:yaroorm/migration/cli.dart';
import 'package:yaroorm/yaroorm.dart';
import '../fixtures/orm_config.dart' as conf;
import '../integration/mariadb.e2e.reflectable.dart';

void main(List<String> args) async {
  if (args.isEmpty) throw UnsupportedError('Provide args');

  initializeReflectable();

  DB.init(conf.config);

  await MigratorCLI.processCmd(args[0], cmdArguments: args.sublist(1));
}
