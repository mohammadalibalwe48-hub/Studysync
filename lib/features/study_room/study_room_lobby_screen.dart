import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';
import 'package:studysync_syria/core/widgets/stat_card.dart';
import 'package:studysync_syria/features/study_room/cloudflare_realtime_client.dart';
import 'package:studysync_syria/features/study_room/study_room_models.dart';

/// Lightweight lobby for study rooms.
///
/// Lets the student type or paste a 6-character room code, optionally
/// flag themselves as the host (used for teacher-led classes), and
/// enter the live room. There is no server-side "rooms" table — the
/// room id is just an arbitrary shared string.
class StudyRoomLobbyScreen extends StatefulWidget {
  const StudyRoomLobbyScreen({super.key, this.initialMode = RoomMode.discussion});

  final RoomMode initialMode;

  @override
  State<StudyRoomLobbyScreen> createState() => _StudyRoomLobbyScreenState();
}

class _StudyRoomLobbyScreenState extends State<StudyRoomLobbyScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _asHost = false;
  late RoomMode _mode = widget.initialMode;

  @override
  void initState() {
    super.initState();
    // Lecture rooms make most sense when you create them as a teacher.
    if (_mode == RoomMode.lecture) {
      _asHost = true;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _generateCode() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final int now = DateTime.now().microsecondsSinceEpoch;
    String out = '';
    int x = now;
    for (int i = 0; i < 6; i += 1) {
      out += chars[x.abs() % chars.length];
      x = x ~/ chars.length;
    }
    return out;
  }

  void _enterRoom() {
    final String code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final String userId =
        AuthService.instance.currentUser?.id ?? 'guest';
    final String displayName =
        AuthService.instance.currentUser?.email?.split('@').first ?? 'طالب';
    context.push(
      '/study-rooms/$code?mode=${_mode.wire}',
      extra: <String, dynamic>{
        'displayName': displayName,
        'isHost': _asHost,
        'userId': userId,
        'mode': _mode.wire,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool configured = CloudflareRealtimeClient().isConfigured;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: _modeTitle(_mode),
                subtitle: _modeSubtitle(_mode),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  children: <Widget>[
                    if (!configured) ...<Widget>[
                      FadeSlideIn(child: _NotConfiguredCard(palette: palette)),
                      const SizedBox(height: 16),
                    ],
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.outline),
                          boxShadow: palette.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionHeader(
                              title: 'الانضمام إلى غرفة',
                              subtitle:
                                  'أدخل رمز الغرفة الذي شاركه معك المعلّم.',
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _codeCtrl,
                              textDirection: TextDirection.ltr,
                              textCapitalization:
                                  TextCapitalization.characters,
                              inputFormatters: <TextInputFormatter>[
                                LengthLimitingTextInputFormatter(12),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: 'A1B2C3',
                                hintTextDirection: TextDirection.ltr,
                                filled: true,
                                fillColor: scheme.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: palette.outline),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Mode selector
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final RoomMode m in RoomMode.values)
                                  ChoiceChip(
                                    label: Text(_modeChipLabel(m)),
                                    avatar: Icon(_modeChipIcon(m), size: 16),
                                    selected: _mode == m,
                                    onSelected: (bool _) {
                                      setState(() {
                                        _mode = m;
                                        if (m == RoomMode.lecture) {
                                          _asHost = true;
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('انضمّ كمضيف (للمعلّم)'),
                              subtitle: const Text(
                                'يفعّل أدوات المضيف مثل كتم الجميع.',
                              ),
                              value: _asHost,
                              // Lock the host toggle ON when creating a
                              // lecture (it doesn't make sense as a
                              // student creating a lecture).
                              onChanged: _mode == RoomMode.lecture
                                  ? null
                                  : (bool v) =>
                                      setState(() => _asHost = v),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: FilledButton.icon(
                                onPressed: configured ? _enterRoom : null,
                                icon: const Icon(Icons.video_call_rounded),
                                label: const Text('دخول الغرفة'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: ActionTile(
                        icon: Icons.shuffle_rounded,
                        title: 'إنشاء رمز عشوائي',
                        subtitle:
                            'يولّد رمزًا قصيرًا وانسخه لمشاركته مع زملائك.',
                        tone: scheme.primary,
                        onTap: () {
                          setState(() => _codeCtrl.text = _generateCode());
                        },
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

String _modeTitle(RoomMode m) {
  switch (m) {
    case RoomMode.discussion:
      return 'غرف الدراسة';
    case RoomMode.voice:
      return 'غرفة صوتية';
    case RoomMode.lecture:
      return 'بثّ معلّم مباشر';
  }
}

String _modeSubtitle(RoomMode m) {
  switch (m) {
    case RoomMode.discussion:
      return 'مكالمات فيديو جماعية وحوار نصّي';
    case RoomMode.voice:
      return 'محادثة صوتية فقط — بدون كاميرا';
    case RoomMode.lecture:
      return 'يبثّ المعلّم؛ الطلاب صامتون افتراضيًا';
  }
}

String _modeChipLabel(RoomMode m) {
  switch (m) {
    case RoomMode.discussion:
      return 'نقاش';
    case RoomMode.voice:
      return 'صوت فقط';
    case RoomMode.lecture:
      return 'بثّ معلّم';
  }
}

IconData _modeChipIcon(RoomMode m) {
  switch (m) {
    case RoomMode.discussion:
      return Icons.groups_3_rounded;
    case RoomMode.voice:
      return Icons.mic_rounded;
    case RoomMode.lecture:
      return Icons.cast_for_education_rounded;
  }
}

class _NotConfiguredCard extends StatelessWidget {
  const _NotConfiguredCard({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.warm.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.warm.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: palette.warm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'الميزة غير مفعّلة',
                  style: TextStyle(
                    color: palette.warm,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'يحتاج هذا التطبيق إلى إعداد متغيّري البيئة:\n'
                  '• CLOUDFLARE_REALTIME_APP_ID\n'
                  '• CLOUDFLARE_REALTIME_APP_TOKEN',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
