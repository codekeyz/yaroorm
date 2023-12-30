import 'dart:convert';

import 'package:yaroo/http/http.dart';
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
class Body extends RequestAnnotation {
  const Body();

  @override
  process(Request request, ControllerMethodParam param) {
    final body = request.body;
    if (body == null) {
      if (param.optional) return null;
      throw RequestValidationError.body('Request Body is required');
    }

    final dtoInstance = param.dto;
    if (dtoInstance != null) return dtoInstance..make(request);

    final type = param.type;
    if (type != dynamic && body.runtimeType != type) throw RequestValidationError.body('Request Body is not valid');

    return body;
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
    if (value == null) {
      return param.optional ? null : throw RequestValidationError.param('Request Param: $paramName is required');
    }

    if (value.runtimeType == param.type) return value;

    final parsedValue = switch (param.type) {
      const (int) => int.tryParse(value),
      const (double) => double.tryParse(value),
      const (bool) => value == 'true',
      const (String) => value.toString(),
      _ => value,
    };
    if (parsedValue == null) throw RequestValidationError.param('Request Param: $paramName is invalid');
    return parsedValue;
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

const param = Param();
const query = Query();
const body = Body();
