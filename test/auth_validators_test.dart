import 'package:coolcare_mobile/features/auth/validators/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.fullName', () {
    const maxError = 'Họ và tên không được quá 100 ký tự.';
    const formatError =
        'Họ tên chỉ gồm chữ cái, khoảng trắng, dấu nháy đơn hoặc gạch nối.';

    test('UTCID01 accepts a Vietnamese name with apostrophe and hyphen', () {
      expect(AuthValidators.fullName("Nguyễn Thị O'Connor-Lê"), isNull);
    });
    test('UTCID02 rejects 101 characters', () {
      expect(AuthValidators.fullName('A' * 101), maxError);
    });
    test('UTCID03 rejects letters mixed with digits', () {
      expect(AuthValidators.fullName('Nguyễn 123'), formatError);
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
      expect(AuthValidators.phone('0999999999'), isNotNull);
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

  test('OTP UTCID02 rejects a five-digit input', () {
    expect(AuthValidators.otp('12345'), 'OTP phải gồm đúng 6 chữ số.');
  });
}
