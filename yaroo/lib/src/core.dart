// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:spookie/spookie.dart' as spookie;
import 'package:yaroo/http/meta.dart';

import '../../http/http.dart';
import '../../http/kernel.dart';
import '_container/container.dart';
import '_reflector/reflector.dart';
import '_router/definition.dart';
import 'config/config.dart';

part './core_impl.dart';

typedef RoutesResolver = List<RouteDefinition> Function();

/// This should really be a mixin but due to a bug in reflectable.dart#324
/// TODO:(codekeyz) make this a mixin when reflectable.dart#324 is fixed
abstract class AppInstance {
  Application get app => Application.instance;
}

abstract interface class Application {
  Application(AppConfig config);

  static late final Application instance;

  String get name;

  String get url;

  int get port;

  AppConfig get config;

  T singleton<T extends Object>(T instance);

  T instanceOf<T extends Object>();

  void useRoutes(RoutesResolver routeResolver);

  void useViewEngine(ViewEngine viewEngine);
}

abstract class ApplicationFactory {
  static late final Kernel _appKernel;

  final AppConfig appConfig;

  ApplicationFactory(Kernel kernel, this.appConfig) {
    _appKernel = kernel;
  }

  Future<void> bootstrap({bool listen = true}) async {
    await _bootstrapComponents(appConfig);

    if (listen) await startServer();
  }

  Future<void> startServer() async {
    final app = Application.instance as _YarooAppImpl;

    await app._createPharaohInstance().listen(port: app.port);
  }

  Future<void> _bootstrapComponents(AppConfig config) async {
    final spanner = Spanner()..addMiddleware('/', bodyParser);
    Application.instance = _YarooAppImpl(config, spanner);

    final providers = config.providers.map((e) => createNewInstance<ServiceProvider>(e));

    /// register dependencies
    for (final provider in providers) {
      await Future.sync(provider.register);
    }

    final globalMdw = ApplicationFactory.globalMiddleware;
    if (globalMdw != null) spanner.addMiddleware<HandlerFunc>('/', globalMdw);

    /// boot providers
    for (final provider in providers) {
      await Future.sync(provider.boot);
    }
  }

  static RequestHandler buildControllerMethod(ControllerMethod method) {
    final params = method.params;

    return (req, res) {
      final methodName = method.methodName;
      final instance = createNewInstance<HTTPController>(method.controller);
      final mirror = inject.reflect(instance);

      mirror
        ..invokeSetter('request', req)
        ..invokeSetter('response', res);

      late Function() methodCall;

      if (params.isNotEmpty) {
        final args = _resolveControllerMethodArgs(req, method);
        methodCall = () => mirror.invoke(methodName, args);
      } else {
        methodCall = () => mirror.invoke(methodName, []);
      }

      return Future.sync(methodCall);
    };
  }

  static List<Object> _resolveControllerMethodArgs(Request request, ControllerMethod method) {
    if (method.params.isEmpty) return [];

    final args = <Object>[];

    for (final param in method.params) {
      final meta = param.meta;
      if (meta != null) {
        args.add(meta.process(request, param));
        continue;
      }
    }
    return args;
  }

  static Iterable<HandlerFunc> resolveMiddlewareForGroup(String group) {
    final middlewareGroup = ApplicationFactory._appKernel.middlewareGroups[group];
    if (middlewareGroup == null) throw ArgumentError('Middleware group `$group` does not exist');
    return middlewareGroup.map(_buildHandlerFunc);
  }

  static HandlerFunc? get globalMiddleware {
    final middleware = ApplicationFactory._appKernel.middleware;
    if (middleware.isEmpty) return null;
    return ApplicationFactory._appKernel.middleware.map(_buildHandlerFunc).reduce((val, e) => val.chain(e));
  }

  static HandlerFunc _buildHandlerFunc(Type type) {
    final instance = createNewInstance<Middleware>(type);
    return instance.handler ?? instance.handle;
  }

  @visibleForTesting
  Future<spookie.Spookie> get tester {
    final app = (Application.instance as _YarooAppImpl);
    return spookie.request(app._createPharaohInstance());
  }
}
