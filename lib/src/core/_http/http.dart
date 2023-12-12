// ignore_for_file: camel_case_types

part of '../core.dart';

mixin _AppInstance {
  Application get app => Application._instance;
}

@inject
abstract class BaseController with _AppInstance {}

@inject
abstract class ServiceProvider with _AppInstance {
  FutureOr<void> boot();
}

@Target({TargetKind.parameter})
class Param {
  const Param(String name);
}

@Target({TargetKind.parameter})
class Body {
  const Body();
}
