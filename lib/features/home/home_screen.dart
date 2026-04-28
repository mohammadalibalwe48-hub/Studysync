import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/student_progress.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/widgets/streak_badge.dart';
import 'package:studysync_syria/core/widgets/subject_card.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String email =
        AuthService.instance.currentUserEmail ?? 'student@studysync.sy';
    final StudentProgress p = StudentProgress.placeholder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudySync Syria'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Progress',
            icon: const Icon(Icons.insert_chart_outlined),
            onPressed: () => context.go('/progress'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Welcome back,',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StreakBadge(days: p.streakDays),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose a subject',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...Curriculum.subjects.map(
              (Subject s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SubjectCard(
                  subject: s,
                  onTap: () => context.go('/subjects/${s.id}'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _QuickLinkRow(
              onProgress: () => context.go('/progress'),
              onProfile: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkRow extends StatelessWidget {
  const _QuickLinkRow({required this.onProgress, required this.onProfile});

  final VoidCallback onProgress;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.insert_chart_outlined,
            label: 'Progress',
            onTap: onProgress,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: onProfile,
          ),
        ),
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
