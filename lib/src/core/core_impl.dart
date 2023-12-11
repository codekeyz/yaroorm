part of 'core.dart';

class _YarooAppImpl extends Application {
  late final YarooAppConfig _config;

  final Spanner _spanner = Spanner();

  @override
  T singleton<T extends Object>(T instance) {
    return _getIt.registerSingleton<T>(instance);
  }

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final reqHandlers = routeResolver.call().methods;
    for (final ctrl in reqHandlers) {
      for (final method in ctrl.mapping.methods) {
        _spanner.addRoute(method, ctrl.mapping.path, ctrl.classMethod);
      }
    }
  }

  @override
  String get name => _config.appName;

  @override
  String get url => _config.appUrl;

  @override
  YarooAppConfig get config => _config;
}
