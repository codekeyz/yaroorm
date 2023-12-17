// ignore_for_file: camel_case_types

part of '../core.dart';

abstract interface class AppInstance {
  Application get app => Application._instance;
}

@inject
abstract class BaseController extends AppInstance {}

@inject
abstract class ServiceProvider extends AppInstance {
  static List<Type> get defaultProviders => [AppServiceProvider];

  FutureOr<void> boot();
}

@Target({TargetKind.parameter})
class Param {
  const Param(String name);
}

@Target({TargetKind.parameter})
class Body {
  final String? param;
  const Body({this.param});
}
