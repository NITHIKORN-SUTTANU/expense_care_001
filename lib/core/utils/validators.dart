class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 60) return 'Name must be at most 60 characters';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return null; // optional fields
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? requiredPositiveNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? goalName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Goal name is required';
    if (value.trim().length > 50) return 'Goal name must be at most 50 characters';
    return null;
  }

  static String? recurringName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length > 80) return 'Name must be at most 80 characters';
    return null;
  }

  static String? note(String? value) {
    if (value != null && value.length > 200) {
      return 'Note must be at most 200 characters';
    }
    return null;
  }
}
