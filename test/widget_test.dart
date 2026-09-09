import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/utils/utils/validators/validate.dart';

void main() {
  group('VoidValidator.validateEmail', () {
    test('rejects an empty value', () {
      expect(VoidValidator.validateEmail(''), isNotNull);
    });

    test('rejects a malformed address', () {
      expect(VoidValidator.validateEmail('not-an-email'), isNotNull);
    });

    test('accepts a well-formed address of any provider', () {
      // Regression check: Forget Password used to only accept @gmail.com.
      expect(VoidValidator.validateEmail('user@example.com'), isNull);
      expect(VoidValidator.validateEmail('user@outlook.com'), isNull);
    });
  });

  group('VoidValidator.validatePassword', () {
    test('rejects a password missing an uppercase letter, digit, or symbol', () {
      expect(VoidValidator.validatePassword('weakpass'), isNotNull);
    });

    test('accepts a password meeting all strength rules', () {
      expect(VoidValidator.validatePassword('Str0ng!Pass'), isNull);
    });
  });
}
