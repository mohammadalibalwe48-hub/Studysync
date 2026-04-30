import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/features/auth/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? error = await AuthService.instance.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
      fullName: _nameCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    context.go('/classes');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: palette.goldGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'حساب جديد للمعلمين',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _labelled(
                      'الاسم الكامل',
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          hintText: 'مثال: أحمد محمد',
                        ),
                        validator: (String? v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'الرجاء إدخال الاسم الكامل.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _labelled(
                      'البريد الإلكتروني',
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          hintText: 'teacher@example.com',
                        ),
                        validator: (String? v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _labelled(
                      'كلمة السر',
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (String? v) {
                          if (v == null || v.length < 6) {
                            return 'كلمة السر يجب ألّا تقل عن 6 أحرف.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: _labelled(
                      'تأكيد كلمة السر',
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (String? v) {
                          if (v == null || v.length < 6) {
                            return 'يرجى تأكيد كلمة السر.';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'كلمتا السر غير متطابقتين.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: AppButton(
                      label: 'إنشاء الحساب',
                      onPressed: _isLoading ? null : _handleSignup,
                      isLoading: _isLoading,
                      icon: Icons.check_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'لدي حساب بالفعل',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppPalette.of(context).muted,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
