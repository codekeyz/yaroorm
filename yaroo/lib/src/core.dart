// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:reflectable/reflectable.dart' as r;
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

class Injectable extends r.Reflectable {
  const Injectable()
      : super(
          r.invokingCapability,
          r.metadataCapability,
          r.newInstanceCapability,
          r.declarationsCapability,
          r.reflectedTypeCapability,
          r.typeRelationsCapability,
          r.instanceInvokeCapability,
          r.subtypeQuantifyCapability,
        );
}

typedef RoutesResolver = List<RouteDefinition> Function();

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
      loader: FileSystemLoader(paths: ['public']),
    );
    app.useViewEngine(JinjaViewEngine(environment));
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

  Future<void> bootstrap({
    bool start_server = true,
  }) async {
    if (dbConfig != null) {
      DB.init(dbConfig!);
      await DB.defaultDriver.connect();
    }

    await _bootstrapComponents(appConfig);

    if (start_server) await startServer();
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
}
