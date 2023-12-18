import 'package:test/scaffolding.dart';
import 'package:zomato/zomato.dart';

import '../bin/zomato.reflectable.dart';
import '../config/app.dart' as a1;

void main() {
  late final ZomatoApp app = ZomatoApp(a1.appConfig);

  setUpAll(() async {
    initializeReflectable();

    await Future.sync(() => app.bootstrap(start_server: false));
  });

  group('Zomato API Tests', () {
    test('should response Hello World', () async {
      await (await app.tester)
          .get('/api/users')
          // .expectHeader('content-type', 'text/plain; charset=utf-8')
          // .expectStatus(200)
          .expectBody('Hey chima 💚')
          .test();
    });
  });
}
