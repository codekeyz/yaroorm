// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';
import 'package:yaroo/db/db.dart';

import '../../http/http.dart';
import '../../http/kernel.dart';
import '_container/container.dart';
import '_reflector/reflector.dart';
import '_router/definition.dart';
import '_router/utils.dart';
import 'config/config.dart';

part './core_impl.dart';

typedef RoutesResolver = List<RouteDefinition> Function();

/// This should really be a mixin but due to a bug in reflectable.dart#324
/// TODO:(codekeyz) make this a mixin when reflectable.dart#324 is fixed
abstract class AppInstance {
  Application get app => Application._instance;
}

abstract interface class Application {
  static final Application _instance = instanceFromRegistry<Application>();

  String get name;

  String get url;

  int get port;

  AppConfig get config;

  T singleton<T extends Object>(T instance);

  void useMiddlewares(List<Middleware> middlewares);

  void useRoutes(RoutesResolver routeResolver);

  void useViewEngine(ViewEngine viewEngine);

  void _useConfig(AppConfig config);
}

class AppServiceProvider extends ServiceProvider {
  @override
  FutureOr<void> boot() {
    /// setup jinja view engine
    final environment = Environment(
      autoReload: false,
      trimBlocks: true,
      leftStripBlocks: true,
      loader: FileSystemLoader(paths: ['public', 'templates'], extensions: {'j2'}),
    );
    app.useViewEngine(JinjaViewEngine(environment, fileExt: 'j2'));
  }
}

abstract class ApplicationFactory {
  final AppConfig appConfig;
  final DatabaseConfig? dbConfig;
  final Kernel _kernel;

  ApplicationFactory(
    this._kernel,
    this.appConfig, {
    this.dbConfig,
  });

  List<Middleware> get globalMiddlewares => [bodyParser];

  Future<void> bootstrap({bool listen = true}) async {
    if (dbConfig != null) {
      DB.init(dbConfig!);
      await DB.defaultDriver.connect();
    }

    await _bootstrapComponents(appConfig);

    if (listen) await startServer();
  }

  Future<void> startServer() async {
    final app = instanceFromRegistry<Application>() as _YarooAppImpl;

    await app._createPharaohInstance().listen(port: app.port);

    await launchUrl(Application._instance.url);
  }

  Future<void> _bootstrapComponents(AppConfig config) async {
    final application = registerSingleton<Application>(_YarooAppImpl(Spanner()));

    application
      .._useConfig(config)
      ..singleton<Kernel>(_kernel)
      ..useMiddlewares(globalMiddlewares);

    /// boostrap providers
    for (final type in appConfig.providers) {
      final provider = createNewInstance<ServiceProvider>(type);
      await registerSingleton(provider).boot();
    }
  }

  @visibleForTesting
  Future<Spookie> get tester {
    final application = (instanceFromRegistry<Application>() as _YarooAppImpl);
    return request(application._createPharaohInstance());
  }

  static RequestHandler buildControllerMethod(ControllerMethod method) {
    return (req, res) async {
      final methodName = method.methodName;
      final instance = createNewInstance<HTTPController>(method.controller);
      final mirror = inject.reflect(instance);

      mirror
        ..invokeSetter('request', req)
        ..invokeSetter('response', res);

      methodCall() => mirror.invoke(methodName, []);

      final result = await Future.sync(methodCall);

      return result;
    };
  }
}
