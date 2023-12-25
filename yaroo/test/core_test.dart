import 'package:spookie/spookie.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/kernel.dart';
import 'package:yaroo/yaroo.dart';

import 'core_test.reflectable.dart';

final appConfig = AppConfig(
    name: 'Test App',
    environment: 'production',
    isDebug: false,
    url: 'http://localhost',
    port: 3000,
    key: 'askdfjal;ksdjkajl;j');

class TestMiddleware extends Middleware {
  @override
  handle(Request req, Response res, NextFunction next) {}
}

class FoobarMiddleware extends Middleware {
  @override
  handle(Request req, Response res, NextFunction next) {}
}

class TestAppKernel extends Kernel {
  final List<Type> middlewares;

  TestAppKernel(this.middlewares);

  @override
  List<Type> get middleware => middlewares;

  @override
  Map<String, List<Type>> get middlewareGroups => {
        'api': [FoobarMiddleware],
        'web': [String]
      };
}

class TestKidsApp extends ApplicationFactory {
  TestKidsApp(Kernel kernel) : super(kernel, appConfig);
}

void main() {
  initializeReflectable();

  group('Core', () {
    group('Kernel', () {
      setUpAll(() {
        TestKidsApp(TestAppKernel([TestMiddleware]));
      });

      test('should resolve global middleware', () {
        final globalMiddleware = ApplicationFactory.globalMiddleware;
        expect(globalMiddleware, isA<HandlerFunc>());
      });

      test('should resolve group middleware ', () {
        final group = Route.middleware('api').group('Users').routes([
          Route.handler(HTTPMethod.GET, '/', (req, res) => null),
        ]);

        expect(group.paths, ['[ALL]: /users', '[GET]: /users/']);
      });

      test('should throw if type is not subtype of Middleware', () {
        final middlewares = ApplicationFactory.resolveMiddlewareForGroup('api');
        expect(middlewares, isA<Iterable<HandlerFunc>>());

        expect(middlewares.length, 1);

        expect(() => ApplicationFactory.resolveMiddlewareForGroup('web'), throwsA(isA<UnsupportedError>()));
      });
    });
  });
}
