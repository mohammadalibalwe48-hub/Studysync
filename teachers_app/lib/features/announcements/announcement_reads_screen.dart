import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/announcements/announcement_models.dart';
import 'package:studysync_syria_teachers/features/announcements/announcement_queries.dart';

/// Drill-down screen showing which students have read a given
/// announcement, sorted by most recent read first.
class AnnouncementReadsScreen extends StatefulWidget {
  const AnnouncementReadsScreen({
    super.key,
    required this.announcementId,
    required this.seenCount,
    required this.totalStudents,
  });

  final String announcementId;
  final int seenCount;
  final int totalStudents;

  @override
  State<AnnouncementReadsScreen> createState() =>
      _AnnouncementReadsScreenState();
}

class _AnnouncementReadsScreenState extends State<AnnouncementReadsScreen> {
  late Future<List<AnnouncementReader>> _future;

  @override
  void initState() {
    super.initState();
    _future = AnnouncementQueries.fetchAnnouncementReaders(
      announcementId: widget.announcementId,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = AnnouncementQueries.fetchAnnouncementReaders(
          announcementId: widget.announcementId,
        ));
    await _future;
  }

  String _formatDate(DateTime d) {
    final DateTime local = d.toLocal();
    final String yyyy = local.year.toString().padLeft(4, '0');
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mi = local.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd · $hh:$mi';
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
                padding: const EdgeInsets.fromLTRB(8, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'قرّاء الإعلان',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${widget.seenCount}/${widget.totalStudents} '
                            'من الطلاب قرأوا الإعلان',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<AnnouncementReader>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<AnnouncementReader>> snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return ListView(children: <Widget>[
                          const SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'تعذّر تحميل القائمة',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final List<AnnouncementReader> readers =
                          snap.data ?? const <AnnouncementReader>[];
                      if (readers.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.visibility_off_outlined,
                            title: 'لا أحد قرأه بعد',
                            description:
                                'سيظهر الطلاب هنا فور قراءتهم للإعلان.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: readers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int i) {
                          final AnnouncementReader r = readers[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 25),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: palette.card,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border:
                                    Border.all(color: palette.outline),
                              ),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        palette.champagne,
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: palette.muted,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          r.displayName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(r.readAt),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: palette.muted,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
