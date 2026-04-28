import 'package:flutter/foundation.dart';

/// Temporary, in-memory auth service used by the frontend-only version.
///
/// The public API (login, signup, signOut, currentUser, isAuthenticated)
/// mirrors what a real Supabase-backed implementation will expose, so
/// switching backends later only requires changing this file.
class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  String? _email;

  /// The currently signed-in user's email, or null if signed out.
  String? get currentUserEmail => _email;

  bool get isAuthenticated => _email != null;

  /// Pretends to authenticate the user.
  ///
  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final String? validationError = _validateCredentials(email, password);
    if (validationError != null) return validationError;

    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _email = email.trim();
    notifyListeners();
    return null;
  }

  /// Pretends to register a new user account.
  ///
  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> signup({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final String? validationError = _validateCredentials(email, password);
    if (validationError != null) return validationError;

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _email = email.trim();
    notifyListeners();
    return null;
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    _email = null;
    notifyListeners();
  }

  String? _validateCredentials(String email, String password) {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) return 'Please enter your email.';
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
