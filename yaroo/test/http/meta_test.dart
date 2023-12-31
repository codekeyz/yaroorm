import 'package:spookie/spookie.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/meta.dart';
import 'package:yaroo/src/_router/definition.dart';

void main() {
  group('Metas', () {
    final pharaoh = Pharaoh()
      ..onError((error, req) {
        final response = Response.create();
        if (error is RequestValidationError) return response.json(error.errorBody, statusCode: 422);
        return response.internalServerError(error.toString());
      });

    group('Param', () {
      test('should use name set in param', () async {
        pharaoh.get('/<userId>/hello', (req, res) {
          final actualParam = Param('userId');
          final result = actualParam.process(req, ControllerMethodParam('user', String));
          return res.ok(result);
        });
        await (await request(pharaoh)).get('/234/hello').expectStatus(200).expectBody('234').test();
      });

      test('should use controller method property name if param name not provided', () async {
        pharaoh.get('/boys/<user>', (req, res) {
          final result = param.process(req, ControllerMethodParam('user', String));
          return res.ok(result);
        });
        await (await request(pharaoh)).get('/boys/499').expectStatus(200).expectBody('499').test();
      });
    });
  });
}
