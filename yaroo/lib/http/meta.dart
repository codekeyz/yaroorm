import 'dart:convert';

import 'package:reflectable/reflectable.dart';
import 'package:yaroo/foundation/validation.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/src/_reflector/reflector.dart';
import 'package:yaroo/src/_router/definition.dart';

abstract class RequestAnnotation<T> {
  const RequestAnnotation();

  T process(Request request, ControllerMethodParam param);
}

// ignore: constant_identifier_names
enum ValidationErrorLocation { Param, Query, Body }

class RequestValidationError extends Error {
  final String message;
  final Map? errors;
  final ValidationErrorLocation location;

  RequestValidationError.param(this.message)
      : location = ValidationErrorLocation.Param,
        errors = null;

  RequestValidationError.query(this.message)
      : location = ValidationErrorLocation.Query,
        errors = null;

  RequestValidationError.body(this.message)
      : location = ValidationErrorLocation.Body,
        errors = null;

  RequestValidationError.errors(this.location, this.errors) : message = '';

  @override
  String toString() => errors != null ? jsonEncode(errors) : message;
}

/// Use this to annotate a parameter in a controller method
/// which will be resolved to the request body.
///
/// Example: create(@Body() user) {}
class Body<T> extends RequestAnnotation<T> {
  const Body();

  @override
  process(Request request, ControllerMethodParam param) {
    final body = request.body;
    if (!param.optional && body == null) throw RequestValidationError.body('Request Body is required');
    if (T != dynamic && body is! T) throw RequestValidationError.body('Request Body is not valid');
    return body;
  }
}

class DTO extends RequestAnnotation<BaseDTO> {
  const DTO();

  @override
  BaseDTO process(Request request, ControllerMethodParam param) {
    final classMirror = dtoReflector.reflectType(param.type) as ClassMirror;
    final instance = classMirror.newInstance(unnamedConstructor, []) as BaseDTO;
    instance.make(request);
    return instance;
  }
}

/// Use this to annotate a parameter in a controller method
/// which will be resolved to a parameter in the request path.
///
/// `/users/<userId>/details` Example: getUser(@Param() String userId) {}
class Param extends RequestAnnotation {
  final String? name;

  const Param([this.name]);

  @override
  process(Request request, ControllerMethodParam param) {
    final paramName = name ?? param.name;
    final value = request.params[paramName] ?? param.defaultValue;
    if (!param.optional && value == null) throw RequestValidationError.param('Request Param: $paramName is required');
    final parsedValue = switch (param.type) {
      const (int) => int.tryParse(value),
      const (double) => double.tryParse(value),
      const (bool) => value == 'true',
      _ => value,
    };
    if (parsedValue == null) throw RequestValidationError.param('Request Param: $paramName is invalid');
    return value;
  }
}

/// Use this to annotate a parameter in a controller method
/// which will be resolved to a parameter in the request query params.
///
/// `/users?name=Chima` Example: searchUsers(@Query() String name) {}
class Query extends RequestAnnotation {
  final String? name;

  const Query([this.name]);

  @override
  process(Request request, ControllerMethodParam param) {
    final paramName = name ?? param.name;
    final value = request.query[paramName] ?? param.defaultValue;
    if (!param.optional && value == null) {
      throw RequestValidationError.query('Request Query Param: $paramName is required');
    }
    final parsedValue = switch (param.type) {
      const (int) => int.tryParse(value),
      const (double) => double.tryParse(value),
      const (bool) => value == 'true',
      _ => value,
    };
    if (parsedValue == null) throw RequestValidationError.query('Request Query Param: $paramName is invalid');
    return value;
  }
}

const dto = DTO();
const param = Param();
const query = Query();
const body = Body();
