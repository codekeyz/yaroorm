import 'dart:io';

import 'package:spookie/spookie.dart';
import 'package:yaroo/foundation/validation.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/meta.dart';
import 'package:yaroo/src/_router/definition.dart';

import 'meta_test.reflectable.dart';

class TestDTO extends BaseDTO {
  String get username;

  String get lastname;

  int get age;
}

void main() {
  initializeReflectable();

  group('Meta', () {
    group('Param', () {
      final pharaoh = Pharaoh()
        ..onError((error, req, res) {
          if (error is RequestValidationError) return res.json(error.errorBody, statusCode: 422);
          return res.internalServerError(error.toString());
        });

      test('should use name set in meta', () async {
        pharaoh.get('/<userId>/hello', (req, res) {
          final actualParam = Param('userId');
          final result = actualParam.process(req, ControllerMethodParam('user', String));
          return res.ok(result);
        });
        await (await request(pharaoh)).get('/234/hello').expectStatus(200).expectBody('234').test();
      });

      test('should use controller method property name if meta name not provided', () async {
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
        ..onError((error, req, res) {
          if (error is RequestValidationError) return res.json(error.errorBody, statusCode: 422);
          return res.internalServerError(error.toString());
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

    group('Header', () {
      final pharaoh = Pharaoh()
        ..onError((error, req, res) {
          if (error is RequestValidationError) return res.json(error.errorBody, statusCode: 422);
          return res.internalServerError(error.toString());
        });

      test('should use name set in meta', () async {
        pharaoh.get('/foo', (req, res) {
          final actualParam = Header(HttpHeaders.authorizationHeader);
          final result = actualParam.process(req, ControllerMethodParam('token', String));
          return res.json(result);
        });
        await (await request(pharaoh))
            .get('/foo', headers: {HttpHeaders.authorizationHeader: 'foo token'})
            .expectStatus(200)
            .expectJsonBody('[foo token]')
            .test();
      });

      test('should use controller method property name if meta name not provided', () async {
        pharaoh.get('/bar', (req, res) {
          final result = header.process(req, ControllerMethodParam('token', String));
          return res.ok(result);
        });
        await (await request(pharaoh))
            .get('/bar', headers: {'token': 'Hello Token'})
            .expectStatus(200)
            .expectBody('[Hello Token]')
            .test();
      });

      test('when Header value not valid', () async {
        pharaoh.get('/moo', (req, res) {
          final result = header.process(req, ControllerMethodParam('age_max', String));
          return res.ok(result.toString());
        });

        await (await request(pharaoh))
            .get('/moo', headers: {'age_max': 'Chima'})
            .expectStatus(200)
            .expectBody('[Chima]')
            .test();

        await (await request(pharaoh))
            .get('/moo')
            .expectStatus(422)
            .expectBody('{"location":"header","errors":["age_max is required"]}')
            .test();
      });
    });

    group('Body', () {
      final pharaoh = Pharaoh()
        ..onError((error, req, res) {
          if (error is RequestValidationError) return res.json(error.errorBody, statusCode: 422);
          return res.internalServerError(error.toString());
        });

      test('should use name set in meta', () async {
        pharaoh.post('/hello', (req, res) {
          final actualParam = Body();
          final result = actualParam.process(req, ControllerMethodParam('reqBody', dynamic));
          return res.json(result);
        });
        await (await request(pharaoh))
            .post('/hello', {'foo': "bar"})
            .expectStatus(200)
            .expectJsonBody({'foo': 'bar'})
            .test();
      });

      test('when body not provided', () async {
        pharaoh.post('/test', (req, res) {
          final result = body.process(req, ControllerMethodParam('reqBody', dynamic));
          return res.ok(result.toString());
        });

        await (await request(pharaoh)).post('/test', null).expectStatus(422).expectJsonBody({
          'location': 'body',
          'errors': ['body is required']
        }).test();

        await (await request(pharaoh))
            .post('/test', {'hello': 'Foo'})
            .expectStatus(200)
            .expectBody('{hello: Foo}')
            .test();
      });

      test('when dto provided', () async {
        final dto = TestDTO();
        final testData = {'username': 'Foo', 'lastname': 'Bar', 'age': 22};

        pharaoh.post('/mongo', (req, res) {
          final actualParam = Body();
          final result = actualParam.process(req, ControllerMethodParam('reqBody', TestDTO, dto: dto));
          return res.json({'username': result is TestDTO ? result.username : null});
        });
        await (await request(pharaoh))
            .post('/mongo', {})
            .expectStatus(422)
            .expectJsonBody({
              'location': 'body',
              'errors': [
                'username: The field is required',
                'lastname: The field is required',
                'age: The field is required'
              ]
            })
            .test();

        await (await request(pharaoh))
            .post('/mongo', testData)
            .expectStatus(200)
            .expectJsonBody({'username': 'Foo'}).test();
      });
    });
  });
}
