import 'package:yaroo/http/http.dart';
import 'package:yaroo/src/_router/definition.dart';

abstract class RequestAnnotation<T> {
  const RequestAnnotation();

  T process(Request request, ControllerMethodParam param);
}

// ignore: constant_identifier_names
enum ValidationErrorLocation { Param, Query, Body }

enum ValidationErrorType { required, invalid }

class RequestValidationError extends Error {
  final String param;
  final ValidationErrorLocation location;
  final ValidationErrorType error;

  RequestValidationError.param(this.param, this.error) : location = ValidationErrorLocation.Param;

  RequestValidationError.query(this.param, this.error) : location = ValidationErrorLocation.Query;

  RequestValidationError.body(this.error)
      : location = ValidationErrorLocation.Body,
        param = 'Body';

  @override
  String toString() => '${location.name} property $param is ${error.name}';
}

/// Use this to annotate a parameter in a controller method
/// which will be resolved to the request body.
///
/// Example: create(@Body() user) {}
class Body<T> extends RequestAnnotation<T?> {
  const Body();

  @override
  process(Request request, ControllerMethodParam param) {
    final body = request.body;
    if (body == null && !param.optional) throw RequestValidationError.body(ValidationErrorType.required);
    return body;
  }
}

/// Use this to annotate a parameter in a controller method
/// which will be resolved to the request body as JSON.
///
/// Example: create(@JsonBody() Map<String, dynamic> body) {}
class JsonBody extends Body<Map<String, dynamic>> {}

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
    if (!param.optional && value == null) throw RequestValidationError.param(paramName, ValidationErrorType.required);
    final parsedValue = switch (param.type) {
      const (int) => int.tryParse(value),
      const (double) => double.tryParse(value),
      const (bool) => value == 'true',
      _ => value,
    };
    if (parsedValue == null) throw RequestValidationError.param(paramName, ValidationErrorType.invalid);
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
    if (!param.optional && value == null) throw RequestValidationError.query(paramName, ValidationErrorType.required);
    final parsedValue = switch (param.type) {
      const (int) => int.tryParse(value),
      const (double) => double.tryParse(value),
      const (bool) => value == 'true',
      _ => value,
    };
    if (parsedValue == null) throw RequestValidationError.query(paramName, ValidationErrorType.invalid);
    return value;
  }
}
