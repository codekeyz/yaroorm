import 'package:spookie/spookie.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/meta.dart';
import 'package:yaroo/src/_router/definition.dart';

void main() {
  group('Metas', () {
    group('Param', () {
      final pharaoh = Pharaoh()
        ..onError((error, req) {
          final response = Response.create();
          if (error is RequestValidationError) return response.json(error.errorBody, statusCode: 422);
          return response.internalServerError(error.toString());
        });

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

      test('when param value not valid', () async {
        pharaoh.get('/test/<userId>', (req, res) {
          final result = Param().process(req, ControllerMethodParam('userId', int));
          return res.ok(result.toString());
        });

        await (await request(pharaoh)).get('/test/asfkd').expectStatus(422).expectJsonBody({
          'location': 'param',
          'errors': ['userId must be a int type']
        }).test();

        await (await request(pharaoh)).get('/test/2345').expectStatus(200).expectBody('2345').test();
      });
    });

    group('Query', () {
      final pharaoh = Pharaoh()
        ..onError((error, req) {
          final response = Response.create();
          if (error is RequestValidationError) return response.json(error.errorBody, statusCode: 422);
          return response.internalServerError(error.toString());
        });

      test('should use name set in query', () async {
        pharaoh.get('/foo', (req, res) {
          final actualParam = Query('userId');
          final result = actualParam.process(req, ControllerMethodParam('user', String));
          return res.ok(result);
        });
        await (await request(pharaoh)).get('/foo?userId=Chima').expectStatus(200).expectBody('Chima').test();
      });

      test('should use controller method property name if Query name not provided', () async {
        pharaoh.get('/bar', (req, res) {
          final result = query.process(req, ControllerMethodParam('userId', String));
          return res.ok(result);
        });
        await (await request(pharaoh)).get('/bar?userId=Precious').expectStatus(200).expectBody('Precious').test();
      });

      test('when Query value not valid', () async {
        pharaoh.get('/moo', (req, res) {
          final result = query.process(req, ControllerMethodParam('name', int));
          return res.ok(result.toString());
        });

        await (await request(pharaoh)).get('/moo?name=Chima').expectStatus(422).expectJsonBody({
          'location': 'query',
          'errors': ['name must be a int type']
        }).test();

        await (await request(pharaoh))
            .get('/moo')
            .expectStatus(422)
            .expectBody('{"location":"query","errors":["name is required"]}')
            .test();

        await (await request(pharaoh)).get('/moo?name=244').expectStatus(200).expectBody('244').test();
      });
    });
  });
}
