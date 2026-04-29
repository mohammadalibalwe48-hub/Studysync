import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/core/widgets/progress_bar.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressSummary? _summary;
  List<StudySessionRow>? _sessions;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ProgressSummary summary =
          await StudySyncQueries.fetchProgressSummary();
      final List<StudySessionRow> sessions =
          await StudySyncQueries.fetchStudySessions(limit: 200);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      tab: MainTab.progress,
      appBar: AppBar(title: const Text('Your progress')),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 80),
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load your progress',
              description: _error ?? '',
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    final ProgressSummary summary = _summary ?? ProgressSummary.empty;
    final List<StudySessionRow> sessions =
        _sessions ?? const <StudySessionRow>[];
    const List<Subject> subjects = Curriculum.subjects;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: 'Completion',
                  value: '${(summary.completionPercent * 100).round()}%',
                  icon: Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Accuracy',
                  value: '${(summary.correctAnswerRate * 100).round()}%',
                  icon: Icons.trending_up,
                  color: AppPalette.of(context).accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _StreakPill(days: summary.streakDays),
              const SizedBox(width: 10),
              _MinutesPill(minutes: summary.studyMinutes),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(
                  color: AppPalette.of(context).muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ChartCard(weeklyMinutes: _weeklyMinutes(sessions)),
          const SizedBox(height: 18),
          Text(
            'Progress by subject',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            _SubjectsEmptyCard()
          else
            ...List<Widget>.generate(subjects.length, (int i) {
              final Subject s = subjects[i];
              final double value =
                  summary.completionBySubject[s.id] ?? 0;
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                child: LabeledProgressBar(
                  label: s.name,
                  value: value,
                  color: s.color,
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Returns 7 buckets of study minutes — index 0 is 6 days ago, index 6
  /// is today (UTC).
  List<double> _weeklyMinutes(List<StudySessionRow> sessions) {
    final List<double> buckets = List<double>.filled(7, 0);
    final DateTime today = DateTime.now().toUtc();
    final DateTime startOfToday =
        DateTime.utc(today.year, today.month, today.day);
    for (final StudySessionRow s in sessions) {
      final DateTime d = s.createdAt.toUtc();
      final DateTime startOfDay = DateTime.utc(d.year, d.month, d.day);
      final int daysAgo = startOfToday.difference(startOfDay).inDays;
      if (daysAgo < 0 || daysAgo > 6) continue;
      buckets[6 - daysAgo] += s.durationMinutes.toDouble();
    }
    return buckets;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.warm.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.local_fire_department_rounded,
            color: palette.warm,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$days day streak',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.warm,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinutesPill extends StatelessWidget {
  const _MinutesPill({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.schedule, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$minutes min total',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.weeklyMinutes});

  final List<double> weeklyMinutes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> labels = _last7DayLabels();
    final double maxObserved = weeklyMinutes.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );
    final double maxY = maxObserved < 30 ? 30 : (maxObserved * 1.2);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Study minutes — last 7 days',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  for (int i = 0; i < weeklyMinutes.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: weeklyMinutes[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: <Color>[
                              scheme.primary.withOpacity(0.6),
                              scheme.primary,
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _last7DayLabels() {
    const List<String> dayLetters = <String>[
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];
    final DateTime today = DateTime.now();
    final List<String> labels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final DateTime d = today.subtract(Duration(days: i));
      // DateTime.weekday: Mon=1..Sun=7
      labels.add(dayLetters[d.weekday - 1]);
    }
    return labels;
  }
}

class _SubjectsEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline),
      ),
      child: const EmptyState(
        compact: true,
        icon: Icons.bar_chart_rounded,
        title: 'No subject progress yet',
        description:
            'Per-subject progress will show up here once you start studying.',
      ),
    );
  }
}
