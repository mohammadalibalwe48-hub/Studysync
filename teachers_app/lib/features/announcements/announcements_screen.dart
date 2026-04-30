import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/announcements/announcement_models.dart';
import 'package:studysync_syria_teachers/features/announcements/announcement_queries.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<ClassAnnouncement>> _future;

  @override
  void initState() {
    super.initState();
    _future = AnnouncementQueries.fetchClassAnnouncements(
      classId: widget.classId,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = AnnouncementQueries.fetchClassAnnouncements(
          classId: widget.classId,
        ));
    await _future;
  }

  Future<void> _composeNew() async {
    final String? body = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => const _ComposeDialog(),
    );
    if (body == null || body.trim().isEmpty) return;
    try {
      await AnnouncementQueries.createAnnouncement(
        classId: widget.classId,
        body: body,
      );
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(ClassAnnouncement a) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل تريد حذف هذا الإعلان؟ لا يمكن التراجع.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AnnouncementQueries.deleteAnnouncement(announcementId: a.id);
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
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
                            'الإعلانات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.className,
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
                  child: FutureBuilder<List<ClassAnnouncement>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<ClassAnnouncement>> snap) {
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
                            title: 'تعذّر تحميل الإعلانات',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final List<ClassAnnouncement> items =
                          snap.data ?? const <ClassAnnouncement>[];
                      if (items.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.campaign_outlined,
                            title: 'لا توجد إعلانات بعد',
                            description: 'انشر أوّل إعلان لطلابك.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          final ClassAnnouncement a = items[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 30),
                            child: _AnnouncementCard(
                              announcement: a,
                              palette: palette,
                              onTap: () => context.push(
                                '/announcements/${a.id}/reads',
                                extra: <String, dynamic>{
                                  'seenCount': a.seenCount,
                                  'totalStudents': a.totalStudents,
                                },
                              ),
                              onDelete: () => _confirmDelete(a),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AppButton(
                  label: 'نشر إعلان جديد',
                  icon: Icons.campaign_rounded,
                  onPressed: _composeNew,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.palette,
    required this.onTap,
    required this.onDelete,
  });

  final ClassAnnouncement announcement;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.outline),
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
                    gradient: palette.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(announcement.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.champagne,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'تمت قراءته من قبل '
                    '${announcement.seenCount}/${announcement.totalStudents} طالب',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: palette.muted,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_left_rounded, color: palette.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposeDialog extends StatefulWidget {
  const _ComposeDialog();

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('نشر إعلان جديد'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 6,
        minLines: 3,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          hintText: 'اكتب نص الإعلان…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final String body = _ctrl.text.trim();
            if (body.isEmpty) return;
            Navigator.of(context).pop(body);
          },
          child: const Text('نشر'),
        ),
      ],
    );
  }
}
