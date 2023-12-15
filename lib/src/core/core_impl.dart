part of 'core.dart';

class _YarooAppImpl implements Application {
  late final YarooAppConfig _appConfig;
  late final Spanner _spanner;
  late final Pharaoh _pharaoh;

  _YarooAppImpl(this._spanner) : _pharaoh = Pharaoh()..useSpanner(_spanner);

  @override
  T singleton<T extends Object>(T instance) {
    return registerSingleton<T>(instance);
  }

  @override
  void _useConfig(YarooAppConfig appConfig) {
    _appConfig = appConfig;
  }

  @override
  void useMiddlewares(List<Middleware> middlewares) {
    for (final mdw in middlewares) {
      _spanner.addMiddleware('/', mdw);
    }
  }

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final routeDefns = routeResolver.call();
    for (var defn in routeDefns) {
      defn.commit(_spanner);
    }
  }

  @override
  void useViewEngine(ViewEngine viewEngine) {
    _pharaoh.viewEngine = viewEngine;
  }

  @override
  YarooAppConfig get config => _appConfig;

  @override
  String get name => config.appName;

  @override
  String get url => config.appUri.toString();

  @override
  int get port => config.appPort;

  Future<Pharaoh> _startServer() {
    return _pharaoh.listen(port: port);
  }
}
