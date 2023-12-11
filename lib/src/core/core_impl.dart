part of 'core.dart';

class _YarooAppImpl extends Application {
  late final YarooAppConfig _config;

  final Spanner _spanner = Spanner();

  @override
  T singleton<T extends Object>(T instance) {
    return _getIt.registerSingleton<T>(instance);
  }

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
  }

  @override
  String get name => _config.appName;

  @override
  String get url => _config.appUrl;

  @override
  YarooAppConfig get config => _config;
}
