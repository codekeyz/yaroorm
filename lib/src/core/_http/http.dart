// ignore_for_file: camel_case_types

part of '../core.dart';

class Injectable extends Reflectable {
  const Injectable()
      : super(
          invokingCapability,
          newInstanceCapability,
          declarationsCapability,
          reflectedTypeCapability,
          typeRelationsCapability,
          instanceInvokeCapability,
          subtypeQuantifyCapability,
        );
}

const inject = Injectable();

mixin _AppInstance {
  Application get app => Application._instance;
}

@inject
abstract class BaseController with _AppInstance {}

@inject
abstract class ServiceProvider with _AppInstance {
  static List<Type> get defaultProviders => [
        PharaohServiceProvider,
      ];

  FutureOr<void> boot();
}
