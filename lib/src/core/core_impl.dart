part of 'core.dart';

class _YarooAppImpl extends Application {
  late final YarooAppConfig _appConfig;

  Spanner get spanner => Application._spanner;

  @override
  T singleton<T extends Object>(T instance) {
    return _getIt.registerSingleton<T>(instance);
  }

  @override
  void _useConfig(YarooAppConfig appConfig) {
    _appConfig = appConfig;
  }

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final routeDefns = routeResolver.call();
    for (var defn in routeDefns) {
      defn.commit(spanner);
    }
  }

  @override
  void useMiddlewares(List<Middleware> middleware) {
    for (final middleware in middleware) {
      spanner.addMiddleware('/', middleware);
    }
  }

  @override
  YarooAppConfig get config => _appConfig;

  @override
  String get name => config.appName;

  @override
  String get url => config.appUri.toString();

  @override
  int get port => config.appPort;
}
