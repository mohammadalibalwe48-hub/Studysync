import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
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
              title: 'تعذّر تحميل تقدّمك',
              description: _error ?? '',
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
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
    final AppPalette palette = AppPalette.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: <Widget>[
          const FadeSlideIn(
            child: _ScreenHeading(
              title: 'تقدّمك',
              subtitle:
                  'تابع دقائق الدراسة ونسبة الصح والأيام المتتالية في لمحة واحدة.',
            ),
          ),
          const SizedBox(height: 20),
          // Bento grid: 2-column stat cards.
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'الإنجاز',
                    value: (summary.completionPercent * 100).round(),
                    suffix: '%',
                    icon: Icons.check_circle_outline_rounded,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'نسبة الصح',
                    value: (summary.correctAnswerRate * 100).round(),
                    suffix: '%',
                    icon: Icons.gps_fixed_rounded,
                    color: palette.warm,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'أيام الدراسة',
                    value: summary.streakDays,
                    suffix: ' يوم',
                    icon: Icons.local_fire_department_rounded,
                    color: palette.warm,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'دقائق الدراسة',
                    value: summary.studyMinutes,
                    suffix: ' د',
                    icon: Icons.schedule_rounded,
                    color: palette.info,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: _ChartCard(weeklyMinutes: _weeklyMinutes(sessions)),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: Text(
              'التقدّم حسب المادة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: _SubjectsEmptyCard(),
            )
          else
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.outline, width: 0.6),
                  boxShadow: palette.cardShadow,
                ),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < subjects.length; i++)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 18),
                        child: LabeledProgressBar(
                          label: subjects[i].name,
                          value: summary.completionBySubject[subjects[i].id] ?? 0,
                          color: subjects[i].color,
                          duration:
                              Duration(milliseconds: 900 + i * 120),
                        ),
                      ),
                  ],
                ),
              ),
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

class _ScreenHeading extends StatelessWidget {
  const _ScreenHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13.5, color: palette.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final int value;
  final String suffix;
  final IconData icon;
  final Color color;

  /// When `true`, draws an outer color glow to call attention (used for
  /// the streak counter).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: <BoxShadow>[
          ...palette.cardShadow,
          if (highlight)
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.20),
                  color.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          CountUp(
            value: value,
            builder: (BuildContext context, int v) {
              return RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppTheme.onBackground,
                  ),
                  children: <InlineSpan>[
                    TextSpan(text: '$v'),
                    TextSpan(
                      text: suffix,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatefulWidget {
  const _ChartCard({required this.weeklyMinutes});

  final List<double> weeklyMinutes;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.forward());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final List<String> labels = _last7DayLabels();
    final double maxObserved = widget.weeklyMinutes.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );
    final double maxY = maxObserved < 30 ? 30 : (maxObserved * 1.2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'دقائق الدراسة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.champagne,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'آخر 7 أيام',
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (BuildContext context, _) {
                final double t = _anim.value;
                return BarChart(
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
                          getTitlesWidget:
                              (double value, TitleMeta meta) {
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
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: <BarChartGroupData>[
                      for (int i = 0; i < widget.weeklyMinutes.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: <BarChartRodData>[
                            BarChartRodData(
                              toY: widget.weeklyMinutes[i] * t,
                              width: 16,
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: <Color>[
                                  palette.warm.withOpacity(0.85),
                                  palette.accent,
                                ],
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: palette.champagne,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _last7DayLabels() {
    // حروف أولى بالعربية: اثنين، ثلاثاء، أربعاء، خميس، جمعة، سبت،
    // أحد.
    const List<String> dayLetters = <String>[
      'إ',
      'ث',
      'أ',
      'خ',
      'ج',
      'س',
      'ح',
    ];
    final DateTime today = DateTime.now();
    final List<String> labels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final DateTime d = today.subtract(Duration(days: i));
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: const EmptyState(
        compact: true,
        icon: Icons.bar_chart_rounded,
        title: 'لا يوجد تقدّم بعد',
        description:
            'سيظهر تقدمك في كل مادة هنا بمجرد أن تبدأ الدراسة.',
      ),
    );
  }
}
