// ignore_for_file: avoid_function_literals_in_foreach_calls

part of 'core.dart';

class _YarooAppImpl implements Application {
  late final AppConfig _appConfig;
  late final Spanner _spanner;
  late final ViewEngine _viewEngine;

  _YarooAppImpl(this._spanner);

  @override
  T singleton<T extends Object>(T instance) {
    return registerSingleton<T>(instance);
  }

  @override
  void _useConfig(AppConfig appConfig) {
    _appConfig = appConfig;
  }

  @override
  void useMiddlewares(List<Middleware> middlewares) {
    middlewares.forEach((mdw) => _spanner.addMiddleware<Middleware>('/', mdw));
  }

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final routes = routeResolver.call();
    routes.forEach((route) => route.commit(_spanner));
  }

  @override
  void useViewEngine(ViewEngine viewEngine) {
    _viewEngine = viewEngine;
  }

  @override
  AppConfig get config => _appConfig;

  @override
  String get name => config.name;

  @override
  String get url => config.url;

  @override
  int get port => config.port;

  Pharaoh _createPharaohInstance() => Pharaoh()
    ..useSpanner(_spanner)
    ..viewEngine = _viewEngine;
}
