// lib/core/utils/validators.dart
class Validators {
  static String? validateNotEmpty(String? value, [String message = 'Vui lòng không để trống trường này.']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email.';
    }
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Địa chỉ email không hợp lệ.';
    }
    return null;
  }

  static String? validatePhone(String? value, [String message = 'Số điện thoại không hợp lệ.']) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại.';
    }
    // Ví dụ validator đơn giản, bạn có thể làm phức tạp hơn
    if (value.trim().length < 9 || value.trim().length > 11) {
      return message;
    }
    if (!RegExp(r"^[0-9]+$").hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }
}