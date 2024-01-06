// ignore_for_file: avoid_function_literals_in_foreach_calls

part of 'core.dart';

class _YarooAppImpl implements Application {
  late final AppConfig _appConfig;
  late final Spanner _spanner;

  ViewEngine? _viewEngine;

  ApplicationExceptionsHandler? _exceptionsHandler;

  _YarooAppImpl(this._appConfig, this._spanner);

  @override
  T singleton<T extends Object>(T instance) => registerSingleton<T>(instance);

  @override
  T instanceOf<T extends Object>() => instanceFromRegistry<T>();

  @override
  void useRoutes(RoutesResolver routeResolver) {
    final routes = routeResolver.call();
    routes.forEach((route) => route.commit(_spanner));
  }

  @override
  void useViewEngine(ViewEngine viewEngine) => _viewEngine = viewEngine;

  FutureOr<Response> onException(Object error, Request request, Response response) {
    if (_exceptionsHandler != null) return _exceptionsHandler!.call(error, (req: request, res: response));

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

  @override
  void useErrorHandler(ApplicationExceptionsHandler handler) {
    _exceptionsHandler = handler;
  }
}
