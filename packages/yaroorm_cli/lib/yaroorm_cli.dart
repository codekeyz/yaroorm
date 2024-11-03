library;

import 'package:build/build.dart';

import 'src/builder/generator.dart';

export 'src/yaroorm_cli_base.dart';

/// Builds generators for `build_runner` to run
Builder yaroormBuilder(BuilderOptions options) => generatorFactoryBuilder(options);
