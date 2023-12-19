// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:meta/meta_meta.dart';
import 'package:yaroo/src/_reflector/reflector.dart';
import 'package:yaroo/src/core.dart';

export 'package:pharaoh/pharaoh.dart'
    show
        Request,
        Response,
        Session,
        Middleware,
        HTTPMethod,
        CookieOpts,
        session,
        cookieParser,
        useRequestHandler,
        useShelfMiddleware;

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
