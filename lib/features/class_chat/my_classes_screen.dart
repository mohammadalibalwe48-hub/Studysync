import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/features/class_chat/class_chat_models.dart';
import 'package:studysync_syria/features/class_chat/class_chat_queries.dart';

/// Lists every class the current student is enrolled in, sorted by
/// last-activity. Each row shows a "teacher online" pill (driven by
/// Supabase Realtime presence) and routes to the live chat screen on
/// tap.
class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  late Future<List<StudentClassSummary>> _future;
  List<StudentClassSummary> _items = const <StudentClassSummary>[];
  final List<RealtimeChannel> _presenceChannels = <RealtimeChannel>[];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _disposePresence();
    super.dispose();
  }

  void _disposePresence() {
    for (final RealtimeChannel ch in _presenceChannels) {
      try {
        ch.unsubscribe();
      } catch (_) {/* ignore */}
    }
    _presenceChannels.clear();
  }

  Future<List<StudentClassSummary>> _load() async {
    _disposePresence();
    final List<StudentClassSummary> items =
        await ClassChatQueries.fetchMyClasses();
    if (!mounted) return items;
    setState(() => _items = items);
    // Open a presence channel per class so the "teacher online" pill
    // updates the moment a teacher joins / leaves anywhere.
    for (final StudentClassSummary c in items) {
      final RealtimeChannel ch = ClassChatQueries.joinPresence(
        classId: c.classId,
        role: 'student',
        displayName: null,
        onPresenceChanged: (Set<String> teacherIds) {
          if (!mounted) return;
          final bool online = teacherIds.contains(c.teacherId);
          setState(() {
            _items = <StudentClassSummary>[
              for (final StudentClassSummary item in _items)
                if (item.classId == c.classId)
                  item.copyWith(isTeacherOnline: online)
                else
                  item,
            ];
          });
        },
      );
      _presenceChannels.add(ch);
    }
    return items;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'صفوفي',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<StudentClassSummary>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<StudentClassSummary>> snap) {
                      if (snap.connectionState != ConnectionState.done &&
                          _items.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snap.hasError && _items.isEmpty) {
                        return ListView(children: <Widget>[
                          const SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'تعذّر تحميل صفوفك',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      if (_items.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.school_outlined,
                            title: 'لم تنضمّ إلى أي صف بعد',
                            description:
                                'اطلب من معلّمك رمز الانضمام (6 أحرف)\n'
                                'ثم استخدم زر "الانضمام إلى صف" في الواجبات.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          final StudentClassSummary c = _items[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 30),
                            child: _ClassRow(
                              entry: c,
                              palette: palette,
                              onTap: () => context.push(
                                '/classes/${c.classId}/chat',
                                extra: <String, dynamic>{
                                  'name': c.className,
                                  'teacherName': c.teacherName,
                                  'teacherId': c.teacherId,
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.entry,
    required this.palette,
    required this.onTap,
  });

  final StudentClassSummary entry;
  final AppPalette palette;
  final VoidCallback onTap;

  String _lastActivityLabel(DateTime? when) {
    if (when == null) return 'لا توجد رسائل بعد';
    final Duration delta = DateTime.now().toUtc().difference(when.toUtc());
    if (delta.inMinutes < 1) return 'منذ لحظات';
    if (delta.inMinutes < 60) return 'منذ ${delta.inMinutes} دقيقة';
    if (delta.inHours < 24) return 'منذ ${delta.inHours} ساعة';
    if (delta.inDays < 7) return 'منذ ${delta.inDays} يوم';
    return 'قديم';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String teacherLabel = (entry.teacherName == null ||
            entry.teacherName!.trim().isEmpty)
        ? 'المعلّم'
        : entry.teacherName!.trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.outline),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: palette.goldGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entry.className,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isTeacherOnline)
                        _OnlinePill(palette: palette),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'المعلّم: $teacherLabel',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _lastActivityLabel(entry.lastActivityAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_left_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.palette});
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.success.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.success.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: palette.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'المعلّم متصل',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: palette.success,
            ),
          ),
        ],
      ),
    );
  }
}
