import 'dart:convert';

import 'package:ez_validator/ez_validator.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/src/_router/definition.dart';

abstract class RequestAnnotation<T> {
  const RequestAnnotation();

  T process(Request request, ControllerMethodParam param);
}

enum ValidationErrorLocation { param, query, body, header }

class RequestValidationError extends Error {
  final String message;
  final Map? errors;
  final ValidationErrorLocation location;

  RequestValidationError.param(this.message)
      : location = ValidationErrorLocation.param,
        errors = null;

  RequestValidationError.header(this.message)
      : location = ValidationErrorLocation.header,
        errors = null;

  RequestValidationError.query(this.message)
      : location = ValidationErrorLocation.query,
        errors = null;

  RequestValidationError.body(this.message)
      : location = ValidationErrorLocation.body,
        errors = null;

  RequestValidationError.errors(this.location, this.errors) : message = '';

  Map<String, dynamic> get errorBody => {
        'location': location.name,
        if (errors != null) 'errors': errors!.entries.map((e) => '${e.key}: ${e.value}').toList(),
        if (message.isNotEmpty) 'errors': [message],
      };

  @override
  String toString() => errorBody.toString();
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
      throw RequestValidationError.body(EzValidator.globalLocale.required('body'));
    }

    final dtoInstance = param.dto;
    if (dtoInstance != null) return dtoInstance..make(request);

    final type = param.type;
    if (type != dynamic && body.runtimeType != type) {
      throw RequestValidationError.body(EzValidator.globalLocale.isTypeOf('${param.type}', 'body'));
    }

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
      throw RequestValidationError.param(EzValidator.globalLocale.required(paramName));
    }

    final parsedValue = _parseValue(value, param.type);
    if (parsedValue == null) {
      throw RequestValidationError.param(EzValidator.globalLocale.isTypeOf('${param.type}', paramName));
    }
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
      throw RequestValidationError.query(EzValidator.globalLocale.required(paramName));
    }

    final parsedValue = _parseValue(value, param.type);
    if (parsedValue == null) {
      throw RequestValidationError.query(EzValidator.globalLocale.isTypeOf('${param.type}', paramName));
    }
    return parsedValue;
  }
}

class Header extends RequestAnnotation {
  final String? name;
  const Header([this.name]);

  @override
  process(Request request, ControllerMethodParam param) {
    final paramName = name ?? param.name;
    final value = request.headers[paramName] ?? param.defaultValue;
    if (!param.optional && value == null) {
      throw RequestValidationError.header(EzValidator.globalLocale.required(paramName));
    }

    final parsedValue = _parseValue(value, param.type);
    if (parsedValue == null) {
      throw RequestValidationError.query(EzValidator.globalLocale.isTypeOf('${param.type}', paramName));
    }
    return parsedValue;
  }
}

_parseValue(dynamic value, Type type) {
  if (value.runtimeType == type) return value;

  value = value.toString();
  return switch (type) {
    const (int) => int.tryParse(value),
    const (double) => double.tryParse(value),
    const (bool) => value == 'true',
    const (List) || const (Map) => jsonDecode(value),
    _ => value,
  };
}

const param = Param();
const query = Query();
const body = Body();
