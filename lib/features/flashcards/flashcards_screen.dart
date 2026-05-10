import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Anki-style flashcard review for the topic's "key ideas".
///
/// Each card represents one [Topic] from the chosen subject. The front
/// shows the topic title, the back reveals its description and any
/// stored key-idea bullet points. Users tap the card to flip and use
/// "previous / next" arrows to walk through the deck.
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  String? _subjectId;
  int _index = 0;
  bool _flipped = false;

  List<Topic> _deck() {
    if (_subjectId == null) return const <Topic>[];
    return Curriculum.topicsForSubject(_subjectId!)
        .where((Topic t) => t.keyIdeas.isNotEmpty || t.lessonContent.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Topic> deck = _deck();
    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'بطاقات تذكيرية',
                subtitle: _subjectId == null
                    ? 'اختر مادة لبدء الجلسة'
                    : '${_index + 1} من ${deck.length}',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: _subjectId == null
                    ? _buildSubjectPicker(context)
                    : _buildDeck(context, deck),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectPicker(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        const ScreenHeading(
          title: 'اختر مادة للمراجعة',
          subtitle:
              'سنحوّل دروس المادة إلى بطاقات يمكنك المرور عليها بسرعة.',
        ),
        const SizedBox(height: 18),
        for (final Subject s in Curriculum.subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubjectPickRow(
              subject: s,
              count: Curriculum.topicsForSubject(s.id).length,
              onTap: () => setState(() {
                _subjectId = s.id;
                _index = 0;
                _flipped = false;
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDeck(BuildContext context, List<Topic> deck) {
    if (deck.isEmpty) {
      return EmptyState(
        icon: Icons.style_outlined,
        title: 'لا توجد بطاقات بعد',
        description: 'لا تتوفر مفاهيم في هذه المادة حالياً.',
        action: OutlinedButton.icon(
          onPressed: () => setState(() => _subjectId = null),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('اختر مادة أخرى'),
        ),
      );
    }
    final Topic t = deck[_index.clamp(0, deck.length - 1)];
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: <Widget>[
          // Progress indicator across the deck.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_index + 1) / deck.length,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (Widget c, Animation<double> a) {
                  return FadeTransition(
                    opacity: a,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1)
                          .animate(a),
                      child: c,
                    ),
                  );
                },
                child: _flipped
                    ? _CardBack(topic: t, key: ValueKey<String>('b-${t.id}'))
                    : _CardFront(
                        topic: t,
                        key: ValueKey<String>('f-${t.id}'),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton.outlined(
                onPressed: _index == 0
                    ? null
                    : () => setState(() {
                          _index--;
                          _flipped = false;
                        }),
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'السابقة',
              ),
              FilledButton.icon(
                onPressed: () => setState(() => _flipped = !_flipped),
                icon: Icon(_flipped
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                label: Text(_flipped ? 'إخفاء الإجابة' : 'كشف الإجابة'),
              ),
              IconButton.outlined(
                onPressed: _index >= deck.length - 1
                    ? null
                    : () => setState(() {
                          _index++;
                          _flipped = false;
                        }),
                icon: const Icon(Icons.skip_previous_rounded),
                tooltip: 'التالية',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _subjectId = null),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('تغيير المادة'),
          ),
        ],
      ),
    );
  }
}

class _SubjectPickRow extends StatelessWidget {
  const _SubjectPickRow({
    required this.subject,
    required this.count,
    required this.onTap,
  });

  final Subject subject;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.outline, width: 1),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: subject.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(subject.icon, color: subject.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    subject.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count درس متاح للمراجعة',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({super.key, required this.topic});
  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.goldGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'سؤال',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Spacer(),
          Text(
            topic.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اضغط لكشف الفكرة الرئيسية',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.touch_app_outlined,
                size: 18,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Text(
                'انقر للقلب',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key, required this.topic});
  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final List<String> ideas =
        topic.keyIdeas.isEmpty ? <String>[topic.description] : topic.keyIdeas;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline, width: 1),
        boxShadow: palette.cardShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'الفكرة',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              topic.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),
            for (final String idea in ideas) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      idea,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
