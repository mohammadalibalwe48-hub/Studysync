import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/animations.dart';

/// Premium rounded card that previews a topic in a subject's topic list.
class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.topic,
    required this.accentColor,
    required this.onTap,
    this.index,
  });

  final Topic topic;
  final Color accentColor;
  final VoidCallback onTap;

  /// Optional 1-based ordinal rendered as a leading "step number"
  /// medallion. Reinforces the "step-by-step" learning metaphor.
  final int? index;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.outline, width: 0.6),
          boxShadow: palette.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    accentColor.withOpacity(0.20),
                    accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withOpacity(0.20),
                  width: 0.6,
                ),
              ),
              alignment: Alignment.center,
              child: index != null
                  ? Text(
                      '$index',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      Icons.menu_book_outlined,
                      color: accentColor,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}
