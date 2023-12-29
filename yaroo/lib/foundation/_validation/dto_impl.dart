part of 'dto.dart';

abstract interface class _BaseDTOImpl {
  final Map<String, dynamic> _databag = {};

  void make(Request request) {
    final requestBody = request.body ?? {};
    final errors = schema.catchErrors(requestBody);
    if (errors.isNotEmpty) throw RequestValidationError.errors(ValidationErrorLocation.Body, errors);
    _databag.addAll(requestBody);
  }

  EzSchema? _schemaCache;

  EzSchema get schema {
    if (_schemaCache != null) return _schemaCache!;

    final mirror = dtoReflector.reflectType(runtimeType) as r.ClassMirror;
    final properties = mirror.getters;

    final entries = properties.map((prop) {
      final returnType = prop.reflectedReturnType;
      final meta = prop.metadata.whereType<ClassPropertyValidator>().firstOrNull ?? ezRequired(returnType);
      if (meta.propertyType != returnType) {
        throw ArgumentError(
            'Type Mismatch between DTO Meta ${meta.runtimeType} & Property ${prop.simpleName} $returnType');
      }

      return MapEntry(meta.name ?? prop.simpleName, meta.validator);
    });

    final mappedStructure = entries.fold<Map<String, EzValidator<dynamic>>>({}, (prev, curr) {
      prev[curr.key] = curr.value;
      return prev;
    });
    return _schemaCache = EzSchema.shape(mappedStructure, fillSchema: false);
  }
}
