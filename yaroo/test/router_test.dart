import 'package:test/test.dart';
import 'package:yaroo/yaroo.dart';

import './router_test.reflectable.dart';

class TestController extends BaseController {
  void create() {}

  void index() {}

  void show() {}

  void update() {}

  void delete() {}
}

Middleware _testMdw = (req, res, next) {};

void main() {
  setUpAll(() => initializeReflectable());

  group('Router', () {
    group('when route group', () {
      //
      test('with routes', () {
        final routes = Route.group('merchants').routes([
          Route.get('/get', (TestController, #index)),
          Route.delete('/delete', (TestController, #delete)),
          Route.put('/update', (TestController, #update)),
        ]);

        final routePaths = routes.definitions.map((e) => e.route.path).toList();
        expect(routePaths, ['/merchants/get', '/merchants/delete', '/merchants/update']);
      });
      //
      test('with prefix', () {
        final routes = Route.group('Merchants', prefix: 'foo').routes([
          Route.get('/foo', (TestController, #index)),
          Route.delete('/bar', (TestController, #delete)),
          Route.put('/moo', (TestController, #update)),
        ]);

        final routePaths = routes.definitions.map((e) => e.route.path).toList();
        expect(routePaths, ['/foo/foo', '/foo/bar', '/foo/moo']);
      });
      //
      test('with sub groups', () {
        final routes = Route.group('users').routes([
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

        final routePaths = routes.definitions.map((e) => e.route.path).toList();
        expect(routePaths, [
          '/users/get',
          '/users/delete',
          '/users/update',
          '/users/customers/foo',
          '/users/customers/bar',
          '/users/customers/set'
        ]);
      });
      //
      group('when middlewares used', () {
        test('should add to routes', () {
          final routes = Route.group('users', middlewares: [_testMdw]).routes([
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

          final routePaths = routes.definitions.map((e) => e.route.path).toList();
          expect(routePaths, [
            '/users', // middleware is here
            '/users/get',
            '/users/delete',
            '/users/update',
            '/users/customers/foo',
            '/users/customers/bar',
            '/users/customers/set'
          ]);
        });

        test('should chain multiple into one', () {
          final routes = Route.group('users', middlewares: [_testMdw, _testMdw, _testMdw]).routes([
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

          final routePaths = routes.definitions.map((e) => e.route.path).toList();
          expect(routePaths, [
            '/users', // middleware is here
            '/users/get',
            '/users/delete',
            '/users/update',
            '/users/customers/foo',
            '/users/customers/bar',
            '/users/customers/set'
          ]);
        });
      });
    });
  });
}
