// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:reflectable/reflectable.dart' as r;
import 'package:meta/meta_meta.dart';
import 'package:spookie/spookie.dart';
import 'package:yaroorm/yaroorm.dart';

import '../database/manager.dart';
import '_config/config.dart';
import '_container/container.dart';
import '_reflector/reflector.dart';
import '_router/router.dart';
import '_router/utils.dart';

part '_http/http.dart';
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

abstract interface class Application {
  static final Application _instance = instanceFromRegistry<Application>();

  String get name;

  String get url;

  int get port;

  YarooAppConfig get config;

  T singleton<T extends Object>(T instance);

  void useMiddlewares(List<Middleware> middlewares);

  void useRoutes(RoutesResolver routeResolver);

  void _useConfig(YarooAppConfig appConfig);
}

class AppServiceProvider extends ServiceProvider {
  @override
  FutureOr<void> boot() {
    final spanner = Spanner();
    final pharaoh = Pharaoh()..useSpanner(spanner);

    final environment = Environment(
      autoReload: false,
      trimBlocks: true,
      leftStripBlocks: true,
      loader: FileSystemLoader(paths: ['public']),
    );
    pharaoh.viewEngine = JinjaViewEngine(environment);

    registerSingleton<Pharaoh>(pharaoh);
    registerSingleton<Application>(_YarooAppImpl(spanner));
  }
}

abstract class ApplicationFactory {
  final ConfigResolver appConfig;
  final ConfigResolver? dbConfig;

  ApplicationFactory(this.appConfig, {this.dbConfig});

  List<Middleware> get globalMiddlewares => [];

  Future<void> bootstrap({
    bool bootstap_pharaoh = true,
    bool bootstrap_database = true,
    bool start_server = true,
  }) async {
    if (bootstrap_database && dbConfig != null) {
      await DBManager.init(dbConfig!).defaultDriver.connect();
    }

    if (!bootstap_pharaoh) return;

    final config = appConfig.call();
    final providers = config.getValue<List<Type>>(ConfigExt.providers)!;

    await _setupAndBootProviders(providers);

    Application._instance
      .._useConfig(config)
      ..useMiddlewares(globalMiddlewares);

    if (start_server) {
      await instanceFromRegistry<Pharaoh>().listen(port: Application._instance.port);

      await launchUrl(Application._instance.url);
    }
  }

  Future<void> _setupAndBootProviders(List<Type> providers) async {
    for (final type in providers) {
      final provider = createNewInstance<ServiceProvider>(type);
      await registerSingleton(provider).boot();
    }
  }

  Future<void> runMigration(Migration migration, {DatabaseDriver? driver}) async {
    if (dbConfig == null) {
      throw Exception('Database Config Resolver not found');
    }
    driver ??= DBManager.instance.defaultDriver;
  }

  Future<void> runMigrations(List<Migration> migrations, {DatabaseDriver? driver}) async {
    driver ??= DBManager.instance.defaultDriver;
  }

  @visibleForTesting
  Future<Spookie> get tester => request(instanceFromRegistry<Pharaoh>());
}
