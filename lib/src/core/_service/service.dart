part of '../core.dart';

class PharaohServiceProvider extends ServiceProvider {
  @override
  FutureOr<void> boot() {
    _getIt.registerSingleton<Pharaoh>(Pharaoh());
  }
}
