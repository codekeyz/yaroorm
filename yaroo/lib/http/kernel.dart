import 'dart:async';
import 'dart:io';

import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/meta.dart';

import '../src/core.dart';

abstract class Kernel with AppInstance {
  Kernel();

  /// The application's global HTTP middleware stack.
  ///
  /// These middleware are run during every request to your application.
  /// Types here must extends [Middleware].
  final List<Type> middleware = [];

  /// The application's route middleware groups.
  ///
  /// Types here must extends [Middleware].
  final Map<String, List<Type>> middlewareGroups = {};

  FutureOr<Response> onApplicationException(Object error, Request request, Response response) async {
    if (error is RequestValidationError) {
      return response.json(error.errorBody, statusCode: HttpStatus.badRequest);
    } else if (error is SpannerRouteValidatorError) {
      return response.json({
        'errors': [error.toString()]
      }, statusCode: HttpStatus.badRequest);
    }
    return response.internalServerError(error.toString());
  }
}
