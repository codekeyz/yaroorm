import 'package:spookie/spookie.dart';
import 'package:yaroo/yaroo.dart';

import './config_test.reflectable.dart' as r;

Matcher throwsArgumentErrorWithMessage(String message) =>
    throwsA(isA<ArgumentError>().having((p0) => p0.message, '', message));

void main() {
  setUpAll(() => r.initializeReflectable());

  group('App Config Test', () {
    group('should error', () {
      test('when name not provided', () {
        expect(() => AppConfig.fromJson({'url': 'adf.com'}),
            throwsArgumentErrorWithMessage('Invalid value provided for name'));

        expect(
            () => AppConfig.fromJson({'name': ''}), throwsArgumentErrorWithMessage('Empty value not allowed for name'));
      });

      test('when url not provided', () {
        expect(
          () => AppConfig.fromJson({'name': 'Foo Bar'}),
          throwsArgumentErrorWithMessage('Invalid value provided for url'),
        );
      });

      test('when key not provided', () {
        expect(
          () => AppConfig.fromJson({'name': 'Foo Bar', 'url': 'ada.com'}),
          throwsArgumentErrorWithMessage('Invalid value provided for key'),
        );
      });

      test('when providers is not subtype of `ServiceProvider`', () {
        expect(
            () => AppConfig.fromJson({
                  'name': 'Foo Bar',
                  'url': 'ada.com',
                  'providers': [String]
                }),
            throwsArgumentErrorWithMessage('Ensure your provider extends `ServiceProvider` class'));
      });
    });

    test('should return AppConfig instance', () {
      final config = AppConfig.fromJson({
        'name': 'Foo Bar',
        'url': 'http://localhost',
        'key': 'secret',
        'providers': [AppServiceProvider]
      });

      expect(config.name, 'Foo Bar');
      expect(config.url, 'http://localhost');
      expect(config.port, 80);
      expect(config.key, 'secret');
      expect(config.providers, [AppServiceProvider]);
    });

    test('should use prioritize `port` over port in `url`', () {
      final config = AppConfig.fromJson({
        'name': 'Foo Bar',
        'url': 'http://localhost:3000',
        'key': 'secret',
        'port': 4000,
        'providers': [AppServiceProvider]
      });

      expect(config.name, 'Foo Bar');
      expect(config.url, 'http://localhost:4000');
      expect(config.port, 4000);
      expect(config.key, 'secret');
      expect(config.providers, [AppServiceProvider]);
    });

    test('should use default `80` if no port and none in `url`', () {
      final config = AppConfig.fromJson({
        'name': 'Foo Bar',
        'url': 'http://localhost',
        'key': 'secret',
        'providers': [AppServiceProvider]
      });

      expect(config.name, 'Foo Bar');
      expect(config.url, 'http://localhost');
      expect(config.port, 80);
      expect(config.key, 'secret');
      expect(config.providers, [AppServiceProvider]);
    });
  });

  group('Database Config Test', () {
    test('should require default connection', () {
      expect(() => DatabaseConfig.from({}), throwsArgumentErrorWithMessage('Default database connection not provided'));
    });

    test('should require connection infos', () {
      expect(() => DatabaseConfig.from({'default': 'sqlite'}),
          throwsArgumentErrorWithMessage('Database connection infos not provided'));
    });

    test('should error when default connection info not found ', () {
      expect(
          () => DatabaseConfig.from({
                'default': 'sqlite',
                'connections': {
                  'mysql': {'driver': 'sqlite', 'database': 'foo.db'}
                }
              }),
          throwsArgumentErrorWithMessage('Database connection info not found for sqlite'));
    });

    test(
        'should initialize correctly',
        () => expect(
            DatabaseConfig.from({
              'default': 'sqlite',
              'connections': {
                'sqlite': {'driver': 'sqlite', 'database': 'foo.db'}
              }
            }),
            isA<DatabaseConfig>()));
  });
}
