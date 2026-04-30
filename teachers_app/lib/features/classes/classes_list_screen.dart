import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/auth/auth_service.dart';
import 'package:studysync_syria_teachers/features/classes/create_class_dialog.dart';

class ClassesListScreen extends StatefulWidget {
  const ClassesListScreen({super.key});

  @override
  State<ClassesListScreen> createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends State<ClassesListScreen> {
  late Future<List<TeacherClass>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherQueries.fetchClasses();
  }

  Future<void> _refresh() async {
    setState(() => _future = TeacherQueries.fetchClasses());
    await _future;
  }

  Future<void> _openCreateDialog() async {
    final String? newName = await showDialog<String>(
      context: context,
      builder: (_) => const CreateClassDialog(),
    );
    if (newName == null || newName.trim().isEmpty) return;
    try {
      await TeacherQueries.createClass(name: newName);
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
              _TopBar(
                email: AuthService.instance.currentUserEmail ?? '',
                onProfile: () => context.go('/profile'),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<TeacherClass>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<TeacherClass>> snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return ListView(
                          children: <Widget>[
                            const SizedBox(height: 120),
                            EmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'تعذّر تحميل الصفوف',
                              description: snap.error
                                  .toString()
                                  .replaceFirst('Exception: ', ''),
                            ),
                          ],
                        );
                      }
                      final List<TeacherClass> classes =
                          snap.data ?? const <TeacherClass>[];
                      if (classes.isEmpty) {
                        return ListView(
                          children: const <Widget>[
                            SizedBox(height: 120),
                            EmptyState(
                              icon: Icons.class_outlined,
                              title: 'لا توجد صفوف بعد',
                              description:
                                  'أنشئ أول صف لك وشارك رمز الانضمام مع طلابك.',
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        itemCount: classes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (BuildContext context, int i) {
                          final TeacherClass c = classes[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 40),
                            child: _ClassCard(
                              klass: c,
                              palette: palette,
                              onTap: () => context.push(
                                '/classes/${c.id}',
                                extra: <String, dynamic>{'name': c.name},
                              ),
                              onCopyCode: () {
                                Clipboard.setData(
                                    ClipboardData(text: c.joinCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ رمز الانضمام'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
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
                  label: 'إنشاء صف جديد',
                  onPressed: _openCreateDialog,
                  icon: Icons.add_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.email, required this.onProfile});
  final String email;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: palette.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'صفوفي',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                GoRouter.of(context).push('/curriculum'),
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'المنهج',
          ),
          IconButton(
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.klass,
    required this.palette,
    required this.onTap,
    required this.onCopyCode,
  });

  final TeacherClass klass;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.outline),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    klass.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, size: 22),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${klass.studentCount} طالب/طالبة',
              style: TextStyle(
                fontSize: 13,
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onCopyCode,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.champagne,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.outline),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.vpn_key_rounded,
                        size: 16, color: palette.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'رمز الانضمام: ${klass.joinCode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Icon(Icons.copy_rounded,
                        size: 16, color: palette.muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
