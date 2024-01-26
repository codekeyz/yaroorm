import 'package:spookie/spookie.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/yaroo.dart';

import '../config/config_test.dart';
import 'core_test.reflectable.dart';

const appConfig = AppConfig(
  name: 'Test App',
  environment: 'production',
  isDebug: false,
  url: 'http://localhost',
  port: 3000,
  key: 'askdfjal;ksdjkajl;j',
);

class TestMiddleware extends Middleware {}

class FoobarMiddleware extends Middleware {
  @override
  HandlerFunc get handler => (req, res, next) => next();
}

class TestKidsApp extends ApplicationFactory {
  final AppConfig? config;

  TestKidsApp({
    this.providers = const [],
    this.middlewares = const [],
    this.config,
  }) : super(config ?? appConfig);

  @override
  final List<Type> providers;

  @override
  final List<Type> middlewares;

  @override
  Map<String, List<Type>> get middlewareGroups => {
        'api': [FoobarMiddleware],
        'web': [String]
      };
}

void main() {
  initializeReflectable();

  group('Core', () {
    final testApp = TestKidsApp(middlewares: [TestMiddleware]);

    group('should error', () {
      test('when invalid provider type passed', () {
        expect(() => TestKidsApp(middlewares: [TestMiddleware], providers: [String]),
            throwsArgumentErrorWithMessage('Ensure your class extends `ServiceProvider` class'));
      });

      test('when invalid middleware type passed middlewares is not valid', () {
        expect(() => TestKidsApp(middlewares: [String], providers: [AppServiceProvider]),
            throwsArgumentErrorWithMessage('Ensure your class extends `Middleware` class'));
      });
    });

    test('should resolve global middleware', () {
      expect(testApp.globalMiddleware, isA<HandlerFunc>());
    });

    group('when middleware group', () {
      test('should resolve', () {
        final group = Route.middleware('api').group('Users', [
          Route.route(HTTPMethod.GET, '/', (req, res) => null),
        ]);

        expect(group.paths, ['[ALL]: /users', '[GET]: /users/']);
      });

      test('should error when not exist', () {
        expect(
          () => Route.middleware('foo').group('Users', [
            Route.route(HTTPMethod.GET, '/', (req, res) => null),
          ]),
          throwsA(
            isA<ArgumentError>().having((p0) => p0.message, 'message', 'Middleware group `foo` does not exist'),
          ),
        );
      });
    });

    test('should throw if type is not subtype of Middleware', () {
      final middlewares = ApplicationFactory.resolveMiddlewareForGroup('api');
      expect(middlewares, isA<Iterable<HandlerFunc>>());

      expect(middlewares.length, 1);

      expect(() => ApplicationFactory.resolveMiddlewareForGroup('web'), throwsA(isA<UnsupportedError>()));
    });

    test('should return tester', () async {
      await testApp.bootstrap(listen: false);

      expect(await testApp.tester, isA<Spookie>());
    });
  });
}
