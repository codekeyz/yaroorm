import 'package:build/build.dart';

import 'src/builder/generator.dart';

/// Builds generators for `build_runner` to run
Builder yaroormBuilder(BuilderOptions options) => generatorFactoryBuilder(options);
