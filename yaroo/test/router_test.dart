import 'package:test/test.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/yaroo.dart';

import './router_test.reflectable.dart';
import 'core/core_test.dart';

class TestController extends HTTPController {
  void create() {}

  void index() {}

  void show() {}

  void update() {}

  void delete() {}
}

void main() {
  setUpAll(() => initializeReflectable());

  group('Router', () {
    group('when route group', () {
      test('with routes', () {
        final group = Route.group('merchants').routes([
          Route.get('/get', (TestController, #index)),
          Route.delete('/delete', (TestController, #delete)),
          Route.put('/update', (TestController, #update)),
        ]);

        expect(group.paths, [
          '[GET]: /merchants/get',
          '[DELETE]: /merchants/delete',
          '[PUT]: /merchants/update',
        ]);
      });

      test('with prefix', () {
        final group = Route.group('Merchants', prefix: 'foo').routes([
          Route.get('/foo', (TestController, #index)),
          Route.delete('/bar', (TestController, #delete)),
          Route.put('/moo', (TestController, #update)),
        ]);

        expect(group.paths, [
          '[GET]: /foo/foo',
          '[DELETE]: /foo/bar',
          '[PUT]: /foo/moo',
        ]);
      });

      test('with handler', () {
        final group = Route.group('users').routes([
          Route.route(HTTPMethod.GET, '/my-name', (_, req, res) => null),
        ]);
        expect(group.paths, ['[GET]: /users/my-name']);
      });

      test('with sub groups', () {
        final group = Route.group('users').routes([
          Route.get('/get', (TestController, #index)),
          Route.delete('/delete', (TestController, #delete)),
          Route.put('/update', (TestController, #update)),
          //
          Route.group('customers').routes([
            Route.get('/foo', (TestController, #index)),
            Route.delete('/bar', (TestController, #delete)),
            Route.put('/set', (TestController, #update)),
          ]),
        ]);

        expect(group.paths, [
          '[GET]: /users/get',
          '[DELETE]: /users/delete',
          '[PUT]: /users/update',
          '[GET]: /users/customers/foo',
          '[DELETE]: /users/customers/bar',
          '[PUT]: /users/customers/set',
        ]);
      });

      group('when middlewares used', () {
        test('should add to routes', () {
          final group = Route.group('users').routes([
            Route.get('/get', (TestController, #index)),
            Route.delete('/delete', (TestController, #delete)),
            Route.put('/update', (TestController, #update)),
            //
            Route.group('customers').routes([
              Route.get('/foo', (TestController, #index)),
              Route.delete('/bar', (TestController, #delete)),
              Route.put('/set', (TestController, #update)),
            ]),
          ]);

          expect(group.paths, [
            '[GET]: /users/get',
            '[DELETE]: /users/delete',
            '[PUT]: /users/update',
            '[GET]: /users/customers/foo',
            '[DELETE]: /users/customers/bar',
            '[PUT]: /users/customers/set',
          ]);
        });

        test('should chain multiple into one', () {
          final group = Route.group('users').routes([
            Route.get('/get', (TestController, #index)),
            Route.delete('/delete', (TestController, #delete)),
            Route.put('/update', (TestController, #update)),
            //
            Route.group('customers').routes([
              Route.get('/foo', (TestController, #index)),
              Route.delete('/bar', (TestController, #delete)),
              Route.put('/set', (TestController, #update)),
            ]),
          ]);

          expect(group.paths, [
            '[GET]: /users/get',
            '[DELETE]: /users/delete',
            '[PUT]: /users/update',
            '[GET]: /users/customers/foo',
            '[DELETE]: /users/customers/bar',
            '[PUT]: /users/customers/set',
          ]);
        });
      });

      test('when route resource is used', () {
        final group = Route.group('merchants').routes([
          Route.resource('photos', TestController),
        ]);

        expect(group.paths, [
          '[GET]: /merchants/photos/',
          '[GET]: /merchants/photos/<photoId>',
          '[POST]: /merchants/photos/',
          '[PUT]: /merchants/photos/<photoId>',
          '[PATCH]: /merchants/photos/<photoId>',
          '[DELETE]: /merchants/photos/<photoId>'
        ]);
      });

      test('when used with middleware', () {
        TestKidsApp(TestAppKernel([]));

        final group = Route.middleware('api').group('merchants').routes([
          Route.route(HTTPMethod.GET, '/create', (_, req, res) => null),
          Route.group('users').routes([
            Route.get('/get', (TestController, #index)),
            Route.delete('/delete', (TestController, #delete)),
            Route.put('/update', (TestController, #update)),
            Route.middleware('api').group('hello').routes([
              Route.get('/world', (TestController, #index)),
            ])
          ]),
        ]);

        expect(group.paths, [
          '[ALL]: /merchants',
          '[GET]: /merchants/create',
          '[GET]: /merchants/users/get',
          '[DELETE]: /merchants/users/delete',
          '[PUT]: /merchants/users/update',
          '[ALL]: /merchants/users/hello',
          '[GET]: /merchants/users/hello/world'
        ]);
      });
    });

    test('should error when controller method not found', () {
      expect(
        () => Route.group('Merchants', prefix: 'foo').routes([Route.get('/foo', (TestController, #foobar))]),
        throwsA(isA<ArgumentError>().having((p0) => p0.message, '', 'TestController does not have method  #foobar')),
      );
    });
  });
}
