part of '../core.dart';

final GetIt _getIt = GetIt.instance..registerSingleton<Application>(_YarooAppImpl());

T? getInstanceFromRegistry<T>(Type type) {
  try {
    return _getIt.get(type: type) as T;
  } catch (_) {
    throw Exception('Dependency not found in registry: $type');
  }
}
