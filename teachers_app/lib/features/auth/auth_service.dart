import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';

/// Auth service for the teachers app, backed by Supabase Auth.
///
/// On signup we tag the new user with `role: 'teacher'` in user metadata
/// so the `handle_new_user` trigger inserts the right row in
/// `public.profiles`. RLS in the database restricts what each role can
/// access — the app itself does not need to gate features by role.
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

  User? get currentUser => SupabaseService.auth.currentUser;
  String? get currentUserEmail => currentUser?.email;
  bool get isAuthenticated => SupabaseService.auth.currentSession != null;

  Stream<AuthState> get authStateChanges =>
      SupabaseService.auth.onAuthStateChange;

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
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return _humanizeAuthError(e);
    } catch (_) {
      return 'تعذّر الاتصال بالخادم. تحقّق من اتصالك بالإنترنت.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
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
        data: <String, dynamic>{
          'role': 'teacher',
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
        },
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
