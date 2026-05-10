import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// One row in the (mock) leaderboard.
class _LeaderEntry {
  const _LeaderEntry({
    required this.name,
    required this.studyMinutes,
    required this.streak,
    required this.accuracy,
    required this.color,
  });

  final String name;
  final int studyMinutes;
  final int streak;
  final double accuracy;
  final Color color;
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static String? _displayNameFor(String? email) {
    if (email == null || email.isEmpty) return null;
    final String local = email.split('@').first;
    if (local.isEmpty) return null;
    return local[0].toUpperCase() + local.substring(1);
  }

  static const List<_LeaderEntry> _mock = <_LeaderEntry>[
    _LeaderEntry(
      name: 'سامر شاهين',
      studyMinutes: 412,
      streak: 14,
      accuracy: 0.92,
      color: Color(0xFFE2862F),
    ),
    _LeaderEntry(
      name: 'ليلى قاسم',
      studyMinutes: 388,
      streak: 11,
      accuracy: 0.89,
      color: Color(0xFFC9602B),
    ),
    _LeaderEntry(
      name: 'محمد بلوي',
      studyMinutes: 354,
      streak: 9,
      accuracy: 0.86,
      color: Color(0xFFD68A1A),
    ),
    _LeaderEntry(
      name: 'عبد الرحمن',
      studyMinutes: 311,
      streak: 7,
      accuracy: 0.81,
      color: Color(0xFFB8732A),
    ),
    _LeaderEntry(
      name: 'هدى الزين',
      studyMinutes: 289,
      streak: 6,
      accuracy: 0.78,
      color: Color(0xFF8C5A38),
    ),
    _LeaderEntry(
      name: 'كريم الحسيني',
      studyMinutes: 254,
      streak: 5,
      accuracy: 0.74,
      color: Color(0xFFA0683C),
    ),
    _LeaderEntry(
      name: 'دانيا أيوب',
      studyMinutes: 220,
      streak: 4,
      accuracy: 0.71,
      color: Color(0xFFB87A2A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final String? me = _displayNameFor(AuthService.instance.currentUserEmail);

    // Insert "me" at a plausible position.
    final List<_LeaderEntry> rows = List<_LeaderEntry>.from(_mock);
    if (me != null && me.isNotEmpty) {
      rows.insert(
        3,
        _LeaderEntry(
          name: me,
          studyMinutes: 298,
          streak: 6,
          accuracy: 0.83,
          color: scheme.primary,
        ),
      );
    }
    rows.sort((a, b) => b.studyMinutes.compareTo(a.studyMinutes));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'لوحة المتصدرين',
                subtitle: 'تنافسوا بأسبوع دراسي مكثّف',
                onBack: () => context.go('/library'),
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: <Widget>[
                    FadeSlideIn(
                      child: _Podium(
                        first: rows[0],
                        second: rows.length > 1 ? rows[1] : null,
                        third: rows.length > 2 ? rows[2] : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: const SectionHeader(
                        title: 'الترتيب الكامل',
                        subtitle: 'بناءً على دقائق الدراسة هذا الأسبوع',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List<Widget>.generate(rows.length, (int i) {
                      final _LeaderEntry e = rows[i];
                      final bool isMe =
                          me != null && me.isNotEmpty && e.name == me;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 120 + i * 60),
                          child: _LeaderRow(
                            rank: i + 1,
                            entry: e,
                            highlighted: isMe,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay:
                          Duration(milliseconds: 120 + rows.length * 60 + 60),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: palette.outline, width: 1),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.emoji_events_rounded,
                                color: scheme.onPrimaryContainer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'استمر بدراستك اليومية لرفع رتبتك. '
                                'تحديث اللوحة يحصل تلقائيًا في منتصف الليل.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
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

class _Podium extends StatelessWidget {
  const _Podium({
    required this.first,
    required this.second,
    required this.third,
  });

  final _LeaderEntry first;
  final _LeaderEntry? second;
  final _LeaderEntry? third;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFF6E6), Color(0xFFF1DFC9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline, width: 1),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: _PodiumPlace(
              entry: second,
              rank: 2,
              tone: const Color(0xFFC9602B),
              barHeight: 60,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumPlace(
              entry: first,
              rank: 1,
              tone: const Color(0xFFE2862F),
              barHeight: 88,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumPlace(
              entry: third,
              rank: 3,
              tone: const Color(0xFF8C5A38),
              barHeight: 44,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.rank,
    required this.tone,
    required this.barHeight,
  });

  final _LeaderEntry? entry;
  final int rank;
  final Color tone;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String name = entry?.name ?? '—';
    final String initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((String p) => p.characters.first).join()
        : '—';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.emoji_events_rounded,
                color: Color(0xFFE2862F), size: 22),
          ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tone.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry == null ? '' : '${entry!.studyMinutes} د',
          style: TextStyle(
            fontSize: 11,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: barHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withOpacity(0.18),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: tone.withOpacity(0.5), width: 1),
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.entry,
    required this.highlighted,
  });

  final int rank;
  final _LeaderEntry entry;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Color bg = highlighted
        ? scheme.primaryContainer
        : palette.card;
    final Color borderColor = highlighted
        ? scheme.primary
        : palette.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: borderColor, width: highlighted ? 1.4 : 1),
        boxShadow: highlighted ? palette.goldGlow : palette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: highlighted
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.color,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.name.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: highlighted
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.studyMinutes} دقيقة · سلسلة ${entry.streak} يوم · '
                  '${(entry.accuracy * 100).round()}٪ دقة',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: highlighted
                        ? scheme.onPrimaryContainer.withOpacity(0.85)
                        : palette.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: AppTheme.streakAmber,
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.streak}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
