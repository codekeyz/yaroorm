import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:reflectable/reflectable.dart';
import 'package:spanner/spanner.dart';

import '_config/config.dart';
import '_router/router.dart';

import 'package:collection/collection.dart';
import 'package:reflectable/reflectable.dart' as r;

part '_http/http.dart';
part './core_impl.dart';
part './_service/service.dart';
part './_container/container.dart';
part './_reflector/reflector.dart';

typedef RoutesResolver = List<RouteDefinition> Function();

typedef ConfigResolver = YarooAppConfig Function();

abstract interface class Application {
  static final Application _instance = _getIt.get<Application>();

  String get name;

  String get url;

  YarooAppConfig get config;

  T singleton<T extends Object>(T instance);

  void useRoutes(RoutesResolver routeResolver);
}

abstract class ApplicationFactory {
  final ConfigResolver appConfig;

  ApplicationFactory({
    required this.appConfig,
  });

  List<Middleware> get globalMiddlewares;

  Future<void> bootstrap() async {
    final config = appConfig.call();
    final providers = config.getValue<List<Type>>('providers');

    for (final type in providers) {
      final provider = createNewInstance<ServiceProvider>(ResourceType.provider, type);
      await provider.boot();
    }

    // await Future.wait(
    //   providers.map((e) => Future.sync(() => e.boot())),
    // );
  }
}
