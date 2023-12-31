// ignore_for_file: avoid_function_literals_in_foreach_calls

part of 'core.dart';

class _YarooAppImpl implements Application {
  late final AppConfig _appConfig;
  late final Spanner _spanner;
  late final ViewEngine _viewEngine;

  _YarooAppImpl(this._appConfig, this._spanner);

  @override
  T singleton<T extends Object>(T instance) {
    return registerSingleton<T>(instance);
  }

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final routes = routeResolver.call();
    routes.forEach((route) => route.commit(_spanner));
  }

  @override
  void useViewEngine(ViewEngine viewEngine) => _viewEngine = viewEngine;

  FutureOr<Response> onException(Object error, Request request) {
    final response = Response.create();

    if (error is RequestValidationError) {
      return response.json(error.errorBody, statusCode: HttpStatus.badRequest);
    } else if (error is SpannerRouteValidatorError) {
      return response.json({'error': error.toString()}, statusCode: HttpStatus.badRequest);
    }

    return response.internalServerError(error.toString());
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
    ..onError(onException)
    ..viewEngine = _viewEngine;
}
