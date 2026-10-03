import 'package:coolcare_mobile/features/auth/domain/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.fullName', () {
    test('accepts valid Vietnamese names', () {
      expect(AuthValidators.fullName("Nguyễn Thị O'Connor-Lê"), isNull);
    });

    test('rejects one-character, numeric, and symbol-only names', () {
      for (final value in ['A', '12', '@@', 'Nguyễn 123']) {
        expect(AuthValidators.fullName(value), isNotNull);
      }
    });
  });

  group('AuthValidators.email', () {
    test('accepts a valid email', () {
      expect(AuthValidators.email('customer@coolcare.test'), isNull);
    });

    test('rejects malformed email', () {
      expect(AuthValidators.email('customer@'), isNotNull);
    });
  });

  group('AuthValidators.phone', () {
    test('accepts Vietnamese mobile formats', () {
      expect(AuthValidators.phone('0909 000 011'), isNull);
      expect(AuthValidators.phone('+84909000011'), isNull);
    });

    test('rejects invalid phone', () {
      expect(AuthValidators.phone('12345'), isNotNull);
    });
  });

  group('AuthValidators.password', () {
    test('requires uppercase, lowercase, number and symbol', () {
      expect(AuthValidators.password('CoolCare@123'), isNull);
      expect(AuthValidators.password('CoolCare123'), isNotNull);
      expect(AuthValidators.password('A1@a${'x' * 69}'), isNotNull);
    });
  });

  test('OTP contains exactly six digits', () {
    expect(AuthValidators.otp('123456'), isNull);
    expect(AuthValidators.otp('12345a'), isNotNull);
  });
}
