import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/progress_bar.dart';
import 'package:studysync_syria/core/widgets/streak_badge.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
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
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Could not load your progress.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
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

    final double physics =
        summary.completionBySubject[Curriculum.physics.id] ?? 0;
    final double chemistry =
        summary.completionBySubject[Curriculum.chemistry.id] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
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
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              StreakBadge(days: summary.streakDays),
              const SizedBox(width: 10),
              _MinutesPill(minutes: summary.studyMinutes),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ChartCard(weeklyMinutes: _weeklyMinutes(sessions)),
          const SizedBox(height: 18),
          const Text(
            'Progress by subject',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LabeledProgressBar(
            label: Curriculum.physics.name,
            value: physics,
            color: Curriculum.physics.color,
          ),
          const SizedBox(height: 14),
          LabeledProgressBar(
            label: Curriculum.chemistry.name,
            value: chemistry,
            color: Curriculum.chemistry.color,
          ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC2D8FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.schedule, size: 18, color: Color(0xFF1E40AF)),
          const SizedBox(width: 6),
          Text(
            '$minutes min total',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
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
    final List<String> labels = _last7DayLabels();
    final double maxObserved = weeklyMinutes.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );
    final double maxY = maxObserved < 30 ? 30 : (maxObserved * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Study minutes — last 7 days',
            style: TextStyle(fontWeight: FontWeight.w600),
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
                            style: const TextStyle(fontSize: 12),
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
                          color: Theme.of(context).colorScheme.primary,
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
