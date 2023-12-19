// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:reflectable/reflectable.dart' as r;
import 'package:spookie/spookie.dart';
import 'package:yaroo/orm/orm.dart';

import '../../http/http.dart';
import '../../http/kernel.dart';
import '_config/config.dart';
import '_container/container.dart';
import '_reflector/reflector.dart';
import '_router/definition.dart';
import '_router/utils.dart';

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

  YarooAppConfig get config;

  T singleton<T extends Object>(T instance);

  void useMiddlewares(List<Middleware> middlewares);

  void useRoutes(RoutesResolver routeResolver);

  void useViewEngine(ViewEngine viewEngine);

  void _useConfig(YarooAppConfig appConfig);
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
  final ConfigResolver appConfig;
  final ConfigResolver? dbConfig;
  final Kernel _kernel;

  ApplicationFactory(
    this._kernel,
    this.appConfig, {
    this.dbConfig,
  });

  List<Middleware> get globalMiddlewares => [bodyParser];

  Future<void> bootstrap({
    bool bootstap_pharaoh = true,
    bool bootstrap_database = true,
    bool start_server = true,
  }) async {
    if (bootstrap_database && dbConfig != null) {
      DB.init(dbConfig!);
      await DB.defaultDriver.connect();
    }

    if (bootstap_pharaoh) {
      await _bootstrapComponents(appConfig.call());

      if (start_server) await startServer();
    }
  }

  Future<void> startServer() async {
    final app = instanceFromRegistry<Application>() as _YarooAppImpl;

    await app._createPharaohInstance().listen(port: app.port);

    await launchUrl(Application._instance.url);
  }

  Future<void> _bootstrapComponents(YarooAppConfig appConfig) async {
    final application = registerSingleton<Application>(_YarooAppImpl(Spanner()));

    application
      .._useConfig(appConfig)
      ..singleton<Kernel>(_kernel)
      ..useMiddlewares(globalMiddlewares);

    /// boostrap providers
    final providers = appConfig.getValue<List<Type>>(ConfigExt.providers)!;
    for (final type in providers) {
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
