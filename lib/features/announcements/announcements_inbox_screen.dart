import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/features/announcements/announcement_models.dart';
import 'package:studysync_syria/features/announcements/announcement_queries.dart';

class AnnouncementsInboxScreen extends StatefulWidget {
  const AnnouncementsInboxScreen({super.key});

  @override
  State<AnnouncementsInboxScreen> createState() =>
      _AnnouncementsInboxScreenState();
}

class _AnnouncementsInboxScreenState extends State<AnnouncementsInboxScreen> {
  late Future<List<StudentAnnouncement>> _future;
  List<StudentAnnouncement> _items = const <StudentAnnouncement>[];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StudentAnnouncement>> _load() async {
    final List<StudentAnnouncement> all =
        await AnnouncementQueries.fetchInbox();
    if (mounted) setState(() => _items = all);
    return all;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _toggleAndMarkRead(StudentAnnouncement a, int index) async {
    if (a.isRead) return;
    setState(() {
      _items = <StudentAnnouncement>[
        for (int i = 0; i < _items.length; i++)
          i == index ? _items[i].copyWith(isRead: true) : _items[i],
      ];
    });
    try {
      await AnnouncementQueries.markAsRead(announcementId: a.id);
    } catch (_) {
      // Best-effort: keep the optimistic UI even if the network blip
      // failed — the next refresh will reconcile.
    }
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
                          Icons.arrow_forward_ios_rounded, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        'الإعلانات',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<StudentAnnouncement>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<StudentAnnouncement>> snap) {
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
                            title: 'تعذّر تحميل الإعلانات',
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
                            icon: Icons.campaign_outlined,
                            title: 'لا توجد إعلانات',
                            description:
                                'لم يقم معلّموك بنشر إعلانات بعد.',
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
                          final StudentAnnouncement a = _items[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 30),
                            child: _AnnouncementTile(
                              announcement: a,
                              palette: palette,
                              onTap: () => _toggleAndMarkRead(a, i),
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

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.announcement,
    required this.palette,
    required this.onTap,
  });

  final StudentAnnouncement announcement;
  final AppPalette palette;
  final VoidCallback onTap;

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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: announcement.isRead
                ? palette.outline
                : scheme.primary.withOpacity(0.45),
            width: announcement.isRead ? 0.6 : 1.2,
          ),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(
                        announcement.isRead ? 0.10 : 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.campaign_outlined,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        (announcement.className == null ||
                                announcement.className!.trim().isEmpty)
                            ? 'الإعلانات'
                            : announcement.className!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!announcement.isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'غير مقروء',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              announcement.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (announcement.teacherName != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'المعلّم: ${announcement.teacherName!}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: palette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
