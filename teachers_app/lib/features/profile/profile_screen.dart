import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/features/auth/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String? email = AuthService.instance.currentUserEmail;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.go('/classes'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'الملف الشخصي',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: <Widget>[
                    FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.outline),
                          boxShadow: palette.cardShadow,
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: palette.goldGradient,
                                borderRadius: BorderRadius.circular(36),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.school_rounded,
                                  color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'حساب معلم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: palette.outline),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () async {
                            await AuthService.instance.signOut();
                            if (!context.mounted) return;
                            context.go('/login');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
