import 'dart:async';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';

import '_router/definition.dart';

part './_service/service.dart';

DotEnv? _env;

T? env<T>(String name, [T? defaultValue]) {
  _env ??= DotEnv(quiet: true, includePlatformEnvironment: false)..load();
  final strVal = _env![name];

  if (strVal == null) return defaultValue;
  final parsedVal = switch (T) {
    const (String) => strVal,
    const (int) => int.tryParse(strVal),
    const (num) => num.tryParse(strVal),
    const (double) => double.tryParse(strVal),
    const (List<String>) => jsonDecode(strVal),
    _ => throw PharaohException.value('Unsupported value type used in `env`.'),
  };
  return (parsedVal ?? defaultValue) as T;
}

typedef TurboAppConfig = Map<String, dynamic>;

final GetIt _getIt = GetIt.instance..registerSingleton<TurboApp>(_TurboAppImpl());

typedef RoutesResolver = List<RouteDefinition> Function();

typedef ConfigResolver = TurboAppConfig Function();

abstract interface class TurboApp {
  static TurboApp instance = _getIt.get<TurboApp>();

  TurboAppConfig get config;

  T singleton<T extends Object>(T instance);

  void useRoutes(RoutesResolver routeResolver);

  void useConfig(ConfigResolver config);
}

class _TurboAppImpl extends TurboApp {
  late final TurboAppConfig _config;

  final Spanner _spanner = Spanner();

  @override
  T singleton<T extends Object>(T instance) {
    return _getIt.registerSingleton<T>(instance);
  }

  @override
  TurboAppConfig get config => _config;

  @override
  void useRoutes(RoutesResolver routeResolver) async {
    final routes = routeResolver.call().compressed;
    final reqHandlers = routes.whereType<RouteMethodDefinition>();
    for (final ctrl in reqHandlers) {
      for (final method in ctrl.mapping.methods) {
        _spanner.addRoute(method, ctrl.mapping.path, ctrl.classMethod);
      }
    }
  }

  @override
  void useConfig(ConfigResolver configResolver) {
    _config = configResolver.call();

    print(_config);
  }
}
