import 'dart:convert';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zomato/zomato.dart';

import '../bin/zomato.reflectable.dart';
import '../config/app.dart' as a1;
import '../config/database.dart' as db;

void main() {
  late final ZomatoApp app = ZomatoApp(a1.appConfig, dbConfig: db.config);

  setUpAll(() async {
    initializeReflectable();

    await Future.sync(() => app.bootstrap(start_server: false));
  });

  group('Zomato API Tests', () {
    group('when `create` user', () {
      test('should error when invalid params', () async {
        await (await app.tester)
            .post('/api/users', {})
            .expectStatus(422)
            .expectHeader('content-type', 'application/json; charset=utf-8')
            .expectBody({'error': 'Request body cannot be empty'})
            .test();
      });

      test('should create user', () async {
        final newUserData = {'firstname': 'Foo', 'lastname': 'Bar', 'age': 100};

        await (await app.tester)
            .post('/api/users', newUserData)
            .expectStatus(200)
            .expectHeader('content-type', 'application/json; charset=utf-8')
            .expectBodyCustom((body) => jsonDecode(body), contains('id'))
            .test();
      });
    });
  });
}
