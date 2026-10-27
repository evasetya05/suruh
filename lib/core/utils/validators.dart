/// Form validators shared by auth, checkout and partner forms.
///
/// Each returns `null` when valid, matching the `TextFormField.validator`
/// contract so they can be used directly.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  /// Indonesian mobile numbers: 08... or +628..., or standard international format.
  static final RegExp _indoPhonePattern = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,11}$');
  static final RegExp _genericPhonePattern = RegExp(r'^\+?[0-9]{8,15}$');

  static String? email(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email wajib diisi';
    if (!_emailPattern.hasMatch(input)) return 'Format email tidak valid';
    return null;
  }

  static String? emailOrPhone(String? value) {
    final String input = (value ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
    if (input.isEmpty) return 'Nomor HP atau Email wajib diisi';
    if (input.contains('@')) {
      if (!_emailPattern.hasMatch(input)) return 'Format email tidak valid';
      return null;
    }
    if (!_indoPhonePattern.hasMatch(input) && !_genericPhonePattern.hasMatch(input)) {
      return 'Format nomor HP tidak valid (contoh: 08123456789)';
    }
    return null;
  }

  static String? password(String? value) {
    final String input = value ?? '';
    if (input.isEmpty) return 'Password wajib diisi';
    if (input.length < 6) return 'Gunakan minimal 6 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Konfirmasi password Anda';
    if (value != original) return 'Password tidak cocok';
    return null;
  }

  static String? name(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'Nama lengkap wajib diisi';
    if (input.length < 2) return 'Masukkan nama lengkap Anda';
    return null;
  }

  static String? phone(String? value) {
    final String input = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (input.isEmpty) return 'Nomor telepon wajib diisi';
    if (!_indoPhonePattern.hasMatch(input) && !_genericPhonePattern.hasMatch(input)) {
      return 'Gunakan format Indonesia (contoh: 08123456789 atau +628123456789)';
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
