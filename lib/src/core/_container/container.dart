import 'package:get_it/get_it.dart';

import '../core.dart';

typedef ObjectRegistry<T extends Object> = Map<Type, T>;

typedef ServiceProviderRegistry = ObjectRegistry<ServiceProvider>;

final GetIt _getIt = GetIt.instance..registerSingleton<ServiceProviderRegistry>({});

T? _fromServiceProviderRegistry<T extends Object>(Type type) {
  final serviceProviderRegistry = _getIt.get<ServiceProviderRegistry>();
  final instance = serviceProviderRegistry[type];
  if (instance == null) return null;
  return instance as T;
}

T instanceFromRegistry<T extends Object>({Type? type}) {
  type ??= T;
  final local = _fromServiceProviderRegistry(type);
  if (local != null) return local as T;
  try {
    return _getIt.get(type: type) as T;
  } catch (_) {
    throw Exception('Dependency not found in registry: $type');
  }
}

T registerSingleton<T extends Object>(T instance) {
  if (instance is ServiceProvider) {
    final serviceProviderRegistry = _getIt.get<ServiceProviderRegistry>();
    serviceProviderRegistry[instance.runtimeType] = instance;
  } else {
    instance = _getIt.registerSingleton<T>(instance);
  }
  return instance;
}
