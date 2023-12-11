part of '../core.dart';

abstract class ServiceProvider {
  Application get app => Application._instance;

  FutureOr<void> boot();
}
