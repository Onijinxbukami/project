class ValidationService {
  /// Kiểm tra email hợp lệ
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return "Email cannot be empty";
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return "Invalid email format";
    }

    return null; // Email hợp lệ
  }

  String? validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return 'Phone Number cannot be empty';
    }
    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (!phoneRegex.hasMatch(phoneNumber)) {
      return "Invalid phone number format (must be 10-15 digits)";
    }

    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Password cannot be empty";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters long";
    }

    final passwordRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$');
    if (!passwordRegex.hasMatch(password)) {
      return "Password must contain at least one letter and one number";
    }
    return null;
  }

  String? validateUsername(String username) {
    if (username.isEmpty) {
      return "Username cannot be empty";
    }

    if (username.length < 3) {
      return "Username must be at least 3 characters long";
    }
    return null;
  }
}
