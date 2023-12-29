import 'package:ez_validator/ez_validator.dart';
import 'package:reflectable/reflectable.dart' as r;
import 'package:meta/meta.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/meta.dart';
import 'package:yaroo/src/_reflector/reflector.dart';
import 'package:yaroo/src/_router/utils.dart';

import 'meta.dart';

part 'dto_impl.dart';

const _instanceInvoke = r.InstanceInvokeCapability('^[^_]');

class DtoReflector extends r.Reflectable {
  const DtoReflector()
      : super(r.typeCapability, r.metadataCapability, r.newInstanceCapability, r.declarationsCapability,
            r.reflectedTypeCapability, _instanceInvoke, r.subtypeQuantifyCapability);
}

@protected
const dtoReflector = DtoReflector();

@dtoReflector
abstract class BaseDTO implements _BaseDTOImpl {
  @override
  noSuchMethod(Invocation invocation) {
    final property = symbolToString(invocation.memberName);
    return _databag[property];
  }
}
