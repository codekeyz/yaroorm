part of 'dto.dart';

abstract interface class _BaseDTOImpl {
  final Map<dynamic, dynamic> _databag = {};

  void make(Request request) {
    final (data, errors) = schema.validateSync(request.body ?? {});
    if (errors.isNotEmpty) throw RequestValidationError.errors(ValidationErrorLocation.body, errors);
    _databag.addAll(data);
  }

  EzSchema? _schemaCache;

  EzSchema get schema {
    if (_schemaCache != null) return _schemaCache!;

    final mirror = dtoReflector.reflectType(runtimeType) as r.ClassMirror;
    final properties = mirror.getters.where((e) => e.isAbstract);

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
