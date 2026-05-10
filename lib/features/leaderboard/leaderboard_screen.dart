import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Weekly leaderboard backed by `leaderboard_top` RPC on Supabase.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const List<Color> _avatarTones = <Color>[
    Color(0xFF5B47E0), // indigo primary
    Color(0xFF8472F0), // indigo light
    Color(0xFFB7A8FF), // lavender 300
    Color(0xFFFF9500), // sun orange (brand accent)
    Color(0xFFFFB7C5), // blossom pink
    Color(0xFFE08099), // blossom deep
    Color(0xFFFFD000), // sun yellow
    Color(0xFF7C68F0), // physics lavender
  ];

  bool _loading = true;
  String? _error;
  List<LeaderboardEntry> _rows = const <LeaderboardEntry>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<LeaderboardEntry> rows =
          await StudySyncQueries.fetchLeaderboard(limit: 25);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل لوحة المتصدرين.';
        _loading = false;
      });
    }
  }

  Color _toneFor(int rank) =>
      _avatarTones[(rank - 1) % _avatarTones.length];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'لوحة المتصدرين',
                subtitle: 'الترتيب يعتمد على دقائق الدراسة آخر 7 أيام',
                onBack: () => context.go('/library'),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _buildBody(scheme, palette),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme, AppPalette palette) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'تعذّر تحميل اللوحة',
            description: _error!,
          ),
        ],
      );
    }
    if (_rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'لا متصدّرون بعد هذا الأسبوع',
            description:
                'ابدأ جلسة دراسة لتسجيل أوّل دقائقك وستظهر على لوحة المتصدّرين.',
          ),
        ],
      );
    }

    final LeaderboardEntry first = _rows[0];
    final LeaderboardEntry? second = _rows.length > 1 ? _rows[1] : null;
    final LeaderboardEntry? third = _rows.length > 2 ? _rows[2] : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: <Widget>[
        FadeSlideIn(
          child: _Podium(first: first, second: second, third: third),
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
        ...List<Widget>.generate(_rows.length, (int i) {
          final LeaderboardEntry e = _rows[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeSlideIn(
              delay: Duration(milliseconds: 120 + i * 60),
              child: _LeaderRow(
                rank: i + 1,
                entry: e,
                tone: _toneFor(i + 1),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: Duration(milliseconds: 120 + _rows.length * 60 + 60),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.outline, width: 1),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.emoji_events_rounded,
                    color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'استمر بدراستك اليومية لرفع رتبتك. '
                    'تحديث اللوحة تلقائيّ على مدار الأسبوع.',
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
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({
    required this.first,
    required this.second,
    required this.third,
  });

  final LeaderboardEntry first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF1ECFF), Color(0xFFE6DFFF)],
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
              tone: const Color(0xFF8472F0), // indigo light
              barHeight: 60,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumPlace(
              entry: first,
              rank: 1,
              tone: const Color(0xFFFF9500), // brand orange (winner)
              barHeight: 88,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumPlace(
              entry: third,
              rank: 3,
              tone: const Color(0xFFFFB7C5), // blossom pink
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

  final LeaderboardEntry? entry;
  final int rank;
  final Color tone;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String name = entry?.displayName ?? '—';
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
                color: Color(0xFFFF9500), size: 22),
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
    required this.tone,
  });

  final int rank;
  final LeaderboardEntry entry;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Color bg = entry.isSelf ? scheme.primaryContainer : palette.card;
    final Color borderColor =
        entry.isSelf ? scheme.primary : palette.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: borderColor, width: entry.isSelf ? 1.4 : 1),
        boxShadow: entry.isSelf ? palette.goldGlow : palette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: entry.isSelf
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
              color: tone,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.displayName.characters.isNotEmpty
                  ? entry.displayName.characters.first
                  : '?',
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
                  entry.isSelf ? '${entry.displayName} (أنت)' : entry.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: entry.isSelf
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.studyMinutes} دقيقة هذا الأسبوع',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: entry.isSelf
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
            '${(entry.studyMinutes / 60).toStringAsFixed(1)}h',
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
