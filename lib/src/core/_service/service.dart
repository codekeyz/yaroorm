part of '../core.dart';

abstract class ServiceProvider {
  late final TurboApp app = TurboApp.instance;

  FutureOr<void> boot();
}
