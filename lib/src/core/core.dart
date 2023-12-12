import 'dart:async';

import 'package:reflectable/reflectable.dart' as r;
import 'package:get_it/get_it.dart';
import 'package:meta/meta_meta.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:spanner/spanner.dart';

import '_config/config.dart';
import '_reflector/reflector.dart';
import '_router/router.dart';

import '_router/utils.dart';

part '_http/http.dart';
part './core_impl.dart';
part './_service/service.dart';
part './_container/container.dart';

class Injectable extends r.Reflectable {
  const Injectable()
      : super(
          r.invokingCapability,
          r.newInstanceCapability,
          r.declarationsCapability,
          r.reflectedTypeCapability,
          r.typeRelationsCapability,
          r.instanceInvokeCapability,
          r.subtypeQuantifyCapability,
        );
}

typedef RoutesResolver = List<RouteDefinition> Function();

typedef ConfigResolver = YarooAppConfig Function();

abstract interface class Application {
  static final Application _instance = _getIt.get<Application>();

  static final Pharaoh _pharaoh = Pharaoh();

  static final Spanner _spanner = Spanner();

  String get name;

  String get url;

  int get port;

  YarooAppConfig get config;

  T singleton<T extends Object>(T instance);

  void useMiddlewares(List<Middleware> middlewares);

  void useRoutes(RoutesResolver routeResolver);

  void _useConfig(YarooAppConfig appConfig);
}

abstract class ApplicationFactory {
  final ConfigResolver appConfig;

  ApplicationFactory({
    required this.appConfig,
  });

  List<Middleware> get globalMiddlewares => [];

  Future<void> bootstrap() async {
    final config = appConfig.call();
    final providers = config.getValue<List<Type>>(ConfigExt.providers)!;

    Application._instance._useConfig(config);

    Application._instance.useMiddlewares(globalMiddlewares);

    Application._pharaoh.useSpanner(Application._spanner);

    await _setupAndBootProviders(providers);

    await Application._pharaoh.listen(port: Application._instance.port);

    await launchUrl(Application._instance.url);
  }

  Future<void> _setupAndBootProviders(List<Type> providers) async {
    for (final type in providers) {
      final provider = createNewInstance<ServiceProvider>(type);
      await provider.boot();
    }
  }
}
