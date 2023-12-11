import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';

import '_config/config.dart';
import '_router/router.dart';

part './_controller/controller.dart';
part './_service/service.dart';
part './core_impl.dart';

final GetIt _getIt = GetIt.instance..registerSingleton<Application>(_YarooAppImpl());

typedef RoutesResolver = List<RouteDefinition> Function();

typedef ConfigResolver = YarooAppConfig Function();

abstract interface class Application {
  static final Application _instance = _getIt.get<Application>();

  String get name;

  String get url;

  YarooAppConfig get config;

  T singleton<T extends Object>(T instance);

  void useRoutes(RoutesResolver routeResolver);

  void useConfig(ConfigResolver config);
}

abstract class ApplicationFactory {
  List<ServiceProvider> get providers;

  List<Middleware> get globalMiddlewares;

  Future<void> bootstrap() async {
    await Future.wait(
      providers.map((e) => Future.sync(() => e.boot())),
    );
  }
}
