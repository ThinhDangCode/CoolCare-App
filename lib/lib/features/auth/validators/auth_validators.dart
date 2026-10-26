import 'package:flutter/widgets.dart';

import '../../../app/localization/app_strings.dart';

/// Shared validation rules for authentication forms.
abstract final class AuthValidators {
  static String? requiredText(
    String? value,
    String fieldKey, {
    BuildContext? context,
  }) {
    if (value != null && value.trim().isNotEmpty) return null;
    if (context != null) {
      return context.trArgs('validationRequired', {
        'field': context.tr(fieldKey),
      });
    }
    const fallbackFields = {
      'validationFullNameField': 'họ và tên',
      'validationEmailField': 'email',
      'validationPasswordField': 'mật khẩu',
      'validationConfirmPasswordField': 'xác nhận mật khẩu',
      'phoneNumber': 'số điện thoại',
    };
    return 'Vui lòng nhập ${fallbackFields[fieldKey] ?? fieldKey}.';
  }

  static String? fullName(String? value, {BuildContext? context}) {
    final requiredError = requiredText(
      value,
      'validationFullNameField',
      context: context,
    );
    if (requiredError != null) return requiredError;
    final normalized = value!.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2) {
      return context?.tr('validationFullNameMin') ??
          'Họ và tên phải có ít nhất 2 ký tự.';
    }
    if (normalized.length > 100) {
      return context?.tr('validationFullNameMax') ??
          'Họ và tên không được quá 100 ký tự.';
    }
    if (!RegExp(
      r"^[A-Za-zÀ-ÖØ-öø-ỹĐđ\u0300-\u036F]+(?:[ '\-][A-Za-zÀ-ÖØ-öø-ỹĐđ\u0300-\u036F]+)*$",
    ).hasMatch(normalized)) {
      return context?.tr('validationFullNameFormat') ??
          'Họ tên chỉ gồm chữ cái, khoảng trắng, dấu nháy đơn hoặc gạch nối.';
    }
    return null;
  }

  static String? email(String? value, {BuildContext? context}) {
    final requiredError = requiredText(
      value,
      'validationEmailField',
      context: context,
    );
    if (requiredError != null) return requiredError;
    final normalized = value!.trim();
    if (normalized.length > 254) {
      return context?.tr('validationEmailMax') ??
          'Email không được quá 254 ký tự.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      return context?.tr('validationEmailFormat') ??
          'Email không đúng định dạng.';
    }
    return null;
  }

  static String? phone(String? value, {BuildContext? context}) {
    final requiredError = requiredText(value, 'phoneNumber', context: context);
    if (requiredError != null) return requiredError;
    final normalized = value!.replaceAll(RegExp(r'[\s.-]'), '');
    final localPhone = normalized.startsWith('+84')
        ? '0${normalized.substring(3)}'
        : normalized;
    final validPrefix = RegExp(
      r'^(?:0|\+84)(?:3[2-9]|5[25689]|7[06789]|8[1-689]|9[0-46-9])\d{7}$',
    ).hasMatch(normalized);
    if (!validPrefix || RegExp(r'^0(\d)\1{8}$').hasMatch(localPhone)) {
      return context?.tr('validationPhoneFormat') ??
          'Số điện thoại Việt Nam không hợp lệ.';
    }
    return null;
  }

  static String? password(String? value, {BuildContext? context}) {
    final requiredError = requiredText(
      value,
      'validationPasswordField',
      context: context,
    );
    if (requiredError != null) return requiredError;
    final password = value!;
    if (password.length < 8) {
      return context?.tr('passwordMinLength') ??
          'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    if (password.length > 72) {
      return context?.tr('passwordMaxLength') ??
          'Mật khẩu không được quá 72 ký tự.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return context?.tr('passwordComposition') ??
          'Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt.';
    }
    return null;
  }

  static String? confirmPassword(
    String? value,
    String password, {
    BuildContext? context,
  }) {
    final requiredError = requiredText(
      value,
      'validationConfirmPasswordField',
      context: context,
    );
    if (requiredError != null) return requiredError;
    if (value != password) {
      return context?.tr('passwordMismatch') ?? 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }

  static String? otp(String? value, {BuildContext? context}) {
    if (value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return context?.tr('validationOtpFormat') ??
          'OTP phải gồm đúng 6 chữ số.';
    }
    return null;
  }
}
