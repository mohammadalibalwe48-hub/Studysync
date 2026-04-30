import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/supabase_client.dart';

/// Auth service backed by Supabase Auth.
///
/// Public surface:
/// - [login] / [signIn] — sign in with email + password.
/// - [signup] / [signUp] — create an account with email + password.
/// - [signOut]
/// - [currentUser]
/// - [currentUserEmail]
/// - [isAuthenticated]
/// - [authStateChanges] — stream of [AuthState] from Supabase.
///
/// The service is a [ChangeNotifier] so widgets (and the [GoRouter]
/// `refreshListenable`) rebuild when auth state changes. Supabase persists
/// the session locally, so on cold start `currentUser` may already be
/// populated.
class AuthService extends ChangeNotifier {
  AuthService._internal() {
    _subscription =
        SupabaseService.auth.onAuthStateChange.listen(_handleAuthChange);
  }

  static final AuthService instance = AuthService._internal();

  StreamSubscription<AuthState>? _subscription;

  void _handleAuthChange(AuthState _) {
    notifyListeners();
  }

  /// The currently signed-in Supabase user, or null.
  User? get currentUser => SupabaseService.auth.currentUser;

  /// Convenience: the current user's email, or null when signed out.
  String? get currentUserEmail => currentUser?.email;

  /// True if there is a live Supabase session.
  bool get isAuthenticated => SupabaseService.auth.currentSession != null;

  /// Stream of auth changes, useful for screens that want to react to
  /// sign-in / sign-out events.
  Stream<AuthState> get authStateChanges =>
      SupabaseService.auth.onAuthStateChange;

  /// Signs in with email + password.
  ///
  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) =>
      signIn(email: email, password: password);

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final String? validationError = _validateCredentials(email, password);
    if (validationError != null) return validationError;

    try {
      final AuthResponse response = await SupabaseService.auth
          .signInWithPassword(email: email.trim(), password: password);
      if (response.user == null) {
        return 'تعذّر تسجيل الدخول. حاول مرّة أخرى.';
      }
      // ChangeNotifier will fire via onAuthStateChange too, but notify now
      // so consumers awaiting this future see the new state immediately.
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return _humanizeAuthError(e);
    } catch (_) {
      return 'تعذّر الاتصال بالخادم. تحقّق من اتصالك بالإنترنت.';
    }
  }

  /// Creates an account with email + password.
  ///
  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> signup({
    required String email,
    required String password,
    required String confirmPassword,
  }) =>
      signUp(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

  Future<String?> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final String? validationError = _validateCredentials(email, password);
    if (validationError != null) return validationError;

    if (password != confirmPassword) {
      return 'كلمتا السر غير متطابقتين.';
    }

    try {
      final AuthResponse response = await SupabaseService.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        return 'تعذّر إنشاء الحساب. حاول مرّة أخرى.';
      }
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return _humanizeAuthError(e);
    } catch (_) {
      return 'تعذّر الاتصال بالخادم. تحقّق من اتصالك بالإنترنت.';
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    try {
      await SupabaseService.auth.signOut();
    } finally {
      notifyListeners();
    }
  }

  String? _validateCredentials(String email, String password) {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) return 'الرجاء إدخال البريد الإلكتروني.';
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح.';
    }
    if (password.length < 6) {
      return 'كلمة السر يجب ألّا تقل عن 6 أحرف.';
    }
    return null;
  }

  String _humanizeAuthError(AuthException e) {
    final String message = e.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'البريد الإلكتروني أو كلمة السر غير صحيح.';
    }
    if (message.contains('already registered') ||
        message.contains('user already')) {
      return 'يوجد حساب بهذا البريد الإلكتروني.';
    }
    if (message.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
