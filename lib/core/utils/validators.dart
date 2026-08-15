/// Form input validation utilities with specific, human-readable error messages
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional in registration unless specified
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleanPhone.length < 7 || cleanPhone.length > 15 || !RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'Capacity']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Field']) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }
}
