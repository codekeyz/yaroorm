import 'dart:async';

import 'package:yaroo/src/_reflector/reflector.dart';
import 'package:yaroo/src/core.dart';

import 'http.dart';

export 'package:pharaoh/pharaoh.dart'
    show Request, Response, Session, Middleware, HTTPMethod, CookieOpts, session, cookieParser, useRequestHandler;

@inject
abstract class HTTPController extends AppInstance {
  late final Request request;

  late final Response response;

  Map<String, dynamic> get params => request.params;

  Map<String, dynamic> get queryParams => request.query;

  Map<String, dynamic> get headers => request.headers;

  Session? get session => request.session;

  get body => request.body;

  Response badRequest([String? message]) {
    const status = 422;
    if (message == null) return response.status(status);
    return response.json({'error': message}, statusCode: status);
  }

  Response notFound([String? message]) {
    const status = 404;
    if (message == null) return response.status(status);
    return response.json({'error': message}, statusCode: status);
  }

  Response jsonResponse(data, {int statusCode = 200}) {
    return response.json(data, statusCode: statusCode);
  }

  Response redirectTo(String url, {int statusCode = 302}) {
    return response.redirect(url, statusCode);
  }
}

@inject
abstract class ServiceProvider extends AppInstance {
  static List<Type> get defaultProviders => [AppServiceProvider];

  FutureOr<void> boot();

  bool isAugmentation = false;
}
