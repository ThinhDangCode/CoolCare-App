abstract final class AuthValidators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập $label.';
    return null;
  }

  static String? fullName(String? value) {
    final requiredError = requiredText(value, 'họ và tên');
    if (requiredError != null) return requiredError;
    final normalized = value!.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2) return 'Họ và tên phải có ít nhất 2 ký tự.';
    if (normalized.length > 100) return 'Họ và tên không được quá 100 ký tự.';
    if (!RegExp(
      r"^[A-Za-zÀ-ÖØ-öø-ỹĐđ\u0300-\u036F]+(?:[ '\-][A-Za-zÀ-ÖØ-öø-ỹĐđ\u0300-\u036F]+)*$",
    ).hasMatch(normalized)) {
      return 'Họ tên chỉ gồm chữ cái, khoảng trắng, dấu nháy đơn hoặc gạch nối.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredText(value, 'email');
    if (requiredError != null) return requiredError;
    final normalized = value!.trim();
    if (normalized.length > 254) return 'Email không được quá 254 ký tự.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  static String? phone(String? value) {
    final requiredError = requiredText(value, 'số điện thoại');
    if (requiredError != null) return requiredError;
    final normalized = value!.replaceAll(RegExp(r'[\s.-]'), '');
    if (!RegExp(r'^(0\d{9}|\+84\d{9})$').hasMatch(normalized)) {
      return 'Số điện thoại Việt Nam không hợp lệ.';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredText(value, 'mật khẩu');
    if (requiredError != null) return requiredError;
    final password = value!;
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    if (password.length > 72) return 'Mật khẩu không được quá 72 ký tự.';
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Cần chữ hoa, chữ thường, số và ký tự đặc biệt.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = requiredText(value, 'xác nhận mật khẩu');
    if (requiredError != null) return requiredError;
    if (value != password) return 'Mật khẩu xác nhận không khớp.';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP phải gồm đúng 6 chữ số.';
    }
    return null;
  }
}
