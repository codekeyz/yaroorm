import 'package:test/test.dart';
import 'package:yaroo/foundation/validation.dart';

void main() {
  group('Validation', () {
    group('when `ezRequired`', () {
      test('when passed type as argument', () {
        final requiredValidator = ezRequired(String).validator.build();
        expect(requiredValidator(null), 'The field is required');
        expect(requiredValidator(24), 'The field must be a String type');
        expect(requiredValidator('Foo'), isNull);
      });

      test('when passed type through generics', () {
        final requiredValidator = ezRequired<int>().validator.build();
        expect(requiredValidator(null), 'The field is required');
        expect(requiredValidator('Hello'), 'The field must be a int type');
        expect(requiredValidator(24), isNull);
      });

      test('when mis-matched types', () {
        final requiredValidator = ezRequired<int>().validator.build();
        expect(requiredValidator(null), 'The field is required');
        expect(requiredValidator('Hello'), 'The field must be a int type');
        expect(requiredValidator(24), isNull);
      });
    });

    test('when `ezOptional`', () {
      final optionalValidator = ezOptional(String).validator.build();
      expect(optionalValidator(null), isNull);
      expect(optionalValidator(24), 'The field must be a String type');
      expect(optionalValidator('Foo'), isNull);
    });

    test('when `ezEmail`', () {
      final emailValidator = ezEmail().validator.build();
      expect(emailValidator('foo'), 'The field is not a valid email address');
      expect(emailValidator(24), 'The field must be a String type');
      expect(emailValidator('chima@yaroo.dev'), isNull);
    });

    test('when `ezDateTime`', () {
      var requiredValidator = ezDateTime().validator.build();
      final now = DateTime.now();
      expect(requiredValidator('foo'), 'The field must be a DateTime type');
      expect(requiredValidator(now), isNull);
      expect(requiredValidator(null), 'The field is required');

      requiredValidator = ezDateTime(optional: true).validator.build();
      expect(requiredValidator(null), isNull);
      expect(requiredValidator('df'), 'The field must be a DateTime type');
    });
  });
}
