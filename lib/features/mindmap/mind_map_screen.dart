import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Mind-map view of the curriculum.  Each subject is a hub; topics
/// branch out as orbiting nodes.  Tapping a node navigates to its
/// detail screen.  The whole canvas pans/zooms inside an
/// [InteractiveViewer].
class MindMapScreen extends StatelessWidget {
  const MindMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'الخريطة الذهنية',
                subtitle: 'استعرض روابط المنهج بين المواد والدروس',
                onBack: () => context.go('/library'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: FadeSlideIn(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: palette.outline, width: 1),
                          boxShadow: palette.cardShadow,
                        ),
                        child: const _MindMapCanvas(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.touch_app_rounded,
                        size: 16, color: palette.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'اسحب لتحريك الخريطة، اضغط على أي درس للانتقال إليه.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.muted,
                        ),
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

class _MindMapCanvas extends StatefulWidget {
  const _MindMapCanvas();

  @override
  State<_MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends State<_MindMapCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = Curriculum.subjects;
    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 2.4,
      boundaryMargin: const EdgeInsets.all(120),
      child: SizedBox(
        width: 720,
        height: 640,
        child: AnimatedBuilder(
          animation: _entry,
          builder: (BuildContext context, Widget? _) {
            final double t = Curves.easeOutCubic.transform(_entry.value);
            return CustomPaint(
              painter: _LinkPainter(
                subjects: subjects,
                progress: t,
                color: const Color(0xFFE2862F).withOpacity(0.55),
              ),
              child: _NodeLayer(progress: t),
            );
          },
        ),
      ),
    );
  }
}

class _NodeLayer extends StatelessWidget {
  const _NodeLayer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = Curriculum.subjects;
    final List<Widget> nodes = <Widget>[];

    // Subject hubs sit on a horizontal axis.
    for (int i = 0; i < subjects.length; i++) {
      final Subject s = subjects[i];
      final Offset hubCenter = _hubCenter(i, subjects.length);
      nodes.add(Positioned(
        left: hubCenter.dx - 56,
        top: hubCenter.dy - 56,
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: _Hub(subject: s),
        ),
      ));

      final List<Topic> topics = Curriculum.topicsForSubject(s.id);
      for (int j = 0; j < topics.length; j++) {
        final Offset p = _topicPosition(i, subjects.length, j, topics.length);
        final double topicProgress =
            (progress - 0.3 - 0.05 * j).clamp(0.0, 1.0);
        nodes.add(Positioned(
          left: p.dx - 70,
          top: p.dy - 28,
          width: 140,
          height: 56,
          child: Opacity(
            opacity: topicProgress,
            child: Transform.translate(
              offset: Offset(0, (1 - topicProgress) * 12),
              child: _TopicNode(topic: topics[j], color: s.color),
            ),
          ),
        ));
      }
    }

    return Stack(children: nodes);
  }

  static Offset _hubCenter(int index, int total) {
    const double cx = 360;
    const double cy = 320;
    final double offset = (index - (total - 1) / 2) * 280;
    return Offset(cx + offset, cy);
  }

  static Offset _topicPosition(
      int subjectIndex, int subjectTotal, int topicIndex, int topicTotal) {
    final Offset hub = _hubCenter(subjectIndex, subjectTotal);
    // Distribute topics on a half-circle around the hub.
    final double startAngle = subjectIndex == 0 ? math.pi : 0;
    final double sweep = math.pi; // 180° fan
    final double step =
        topicTotal == 1 ? 0 : sweep / (topicTotal - 1);
    final double angle = startAngle - sweep / 2 +
        (topicTotal == 1 ? sweep / 2 : step * topicIndex);
    const double radius = 200;
    return Offset(
      hub.dx + math.cos(angle) * radius,
      hub.dy + math.sin(angle) * radius,
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({
    required this.subjects,
    required this.progress,
    required this.color,
  });

  final List<Subject> subjects;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < subjects.length; i++) {
      final Subject s = subjects[i];
      final Offset hub = _NodeLayer._hubCenter(i, subjects.length);
      final List<Topic> topics = Curriculum.topicsForSubject(s.id);
      for (int j = 0; j < topics.length; j++) {
        final Offset p =
            _NodeLayer._topicPosition(i, subjects.length, j, topics.length);
        final Paint paint = Paint()
          ..color = s.color.withOpacity(0.45 * progress)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        final Path path = Path()
          ..moveTo(hub.dx, hub.dy)
          ..quadraticBezierTo(
            (hub.dx + p.dx) / 2,
            (hub.dy + p.dy) / 2 - 30,
            p.dx,
            p.dy,
          );
        canvas.drawPath(path, paint);
      }
    }

    // Connect both subject hubs together with a thin link in the
    // middle to show the cross-subject relationship visually.
    if (subjects.length >= 2) {
      final Offset a = _NodeLayer._hubCenter(0, subjects.length);
      final Offset b = _NodeLayer._hubCenter(1, subjects.length);
      final Paint linkPaint = Paint()
        ..color = color.withOpacity(0.3 * progress)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(a, b, linkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinkPainter old) =>
      old.progress != progress || old.color != color;
}

class _Hub extends StatelessWidget {
  const _Hub({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () =>
          GoRouter.of(context).push('/subjects/${subject.id}'),
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              subject.color,
              Color.lerp(subject.color, Colors.black, 0.18) ?? subject.color,
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: subject.color.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white, width: 3),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(subject.icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              subject.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicNode extends StatelessWidget {
  const _TopicNode({required this.topic, required this.color});

  final Topic topic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: () => GoRouter.of(context).push('/topics/${topic.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5), width: 1.4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
