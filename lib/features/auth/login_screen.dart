import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/app_button.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? error = await AuthService.instance.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
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
                  const FadeSlideIn(child: _AuthHero()),
                  const SizedBox(height: 28),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 80),
                    child: _AuthHeading(
                      title: 'أهلاً بعودتك',
                      subtitle: 'تابع رحلتك في الفيزياء والكيمياء.',
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _LabelledField(
                      label: 'البريد الإلكتروني',
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          hintText: 'student@example.com',
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
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: _LabelledField(
                      label: 'كلمة السر',
                      trailing: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'نسيتها؟',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      child: TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
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
                          hintText: '••••••••',
                        ),
                        validator: (String? v) {
                          if (v == null || v.isEmpty) {
                            return 'الرجاء إدخال كلمة السر.';
                          }
                          if (v.length < 6) {
                            return 'كلمة السر يجب ألّا تقل عن 6 أحرف.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _errorMessage != null
                        ? Padding(
                            key: ValueKey<String>(_errorMessage!),
                            padding: const EdgeInsets.only(top: 12),
                            child: _AuthError(message: _errorMessage!),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    child: OrangePillButton(
                      label: 'دخول',
                      icon: Icons.arrow_back_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                      height: 52,
                      expand: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'لا تملك حساباً؟ ',
                          style: TextStyle(
                            color: AppPalette.of(context).muted,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: const Text('أنشئ حساباً'),
                        ),
                      ],
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
}

/// Animated brand emblem (gradient-gold step icon) used at the top of
/// the auth screens.
class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Center(
      child: GlowPulse(
        color: palette.accent,
        minOpacity: 0.10,
        maxOpacity: 0.28,
        blur: 36,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: palette.goldGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.accent.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _AuthHeading extends StatelessWidget {
  const _AuthHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: palette.muted),
        ),
      ],
    );
  }
}

/// Composable label-caps + optional trailing action above an input
/// field, matching the design system's label-caps overlines.
class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: palette.muted,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withOpacity(0.30)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
