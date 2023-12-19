import 'dart:convert';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zomato/app/app.dart';

import '../bin/zomato.reflectable.dart';
import '../config/app.dart' as a1;
import '../config/database.dart' as db;

void main() {
  late final App app = App(a1.appConfig, dbConfig: db.config);

  setUpAll(() async {
    initializeReflectable();

    await app.bootstrap(start_server: false);
  });

  group('Zomato API Tests', () {
    group('when `create` user', () {
      test('should error when invalid params', () async {
        await (await app.tester)
            .post('/api/users', {})
            .expectBody({'error': 'Request body cannot be empty'})
            .expectStatus(422)
            .expectHeader('content-type', 'application/json; charset=utf-8')
            .test();
      });

      test('should create user', () async {
        final newUserData = {'firstname': 'Foo', 'lastname': 'Bar', 'age': 100};

        await (await app.tester)
            .post('/api/users', newUserData)
            .expectBodyCustom(
              (body) => jsonDecode(body),
              allOf([
                contains('id'),
                containsPair('firstname', 'Foo'),
                containsPair('lastname', 'Bar'),
                containsPair('age', 100)
              ]),
            )
            .expectStatus(200)
            .expectHeader('content-type', 'application/json; charset=utf-8')
            .test();
      });
    });
  });
}
