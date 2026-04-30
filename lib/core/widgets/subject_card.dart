import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/widgets/animations.dart';

/// Big tappable "lesson card" representing a subject (e.g. Physics).
///
/// Premium "layered surface" treatment:
/// - Pure off-white card with hairline outline + soft cardShadow.
/// - Tinted gradient strip behind the icon to evoke subject color.
/// - Decorative diffuse glow that reads as ambient lighting.
/// - Animated chevron on press.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color tone = subject.color;
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.outline, width: 0.6),
          boxShadow: palette.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -30,
                top: -30,
                child: IgnorePointer(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          tone.withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            tone.withOpacity(0.20),
                            tone.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: tone.withOpacity(0.30),
                          width: 0.8,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: tone.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(subject.icon, color: tone, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.champagne,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'SUBJECT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: palette.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tone.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: tone,
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
