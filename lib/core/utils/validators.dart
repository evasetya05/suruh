/// Form validators shared by auth, checkout and partner forms.
///
/// Each returns `null` when valid, matching the `TextFormField.validator`
/// contract so they can be used directly.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  /// Malaysian mobile numbers: 01X-XXXXXXX, optionally +60 prefixed.
  static final RegExp _phonePattern = RegExp(r'^(\+?60|0)1\d{8,9}$');

  static String? email(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final String input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'Name is required';
    if (input.length < 2) return 'Enter your full name';
    return null;
  }

  static String? phone(String? value) {
    final String input = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (input.isEmpty) return 'Phone number is required';
    if (!_phonePattern.hasMatch(input)) {
      return 'Enter a valid Malaysian number, e.g. 012-3456789';
    }
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'Price is required';
    final double? parsed = double.tryParse(input);
    if (parsed == null) return 'Enter a number';
    if (parsed <= 0) return 'Price must be greater than 0';
    if (parsed > 9999) return 'Price looks too high';
    return null;
  }
}
