import 'package:flutter/material.dart';

import 'package:studysync_syria/core/models/topic.dart';

/// Read-only lesson body shown at the top of a topic detail screen.
class LessonView extends StatelessWidget {
  const LessonView({
    super.key,
    required this.topic,
    required this.accentColor,
  });

  final Topic topic;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Lesson',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            topic.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topic.description,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            topic.lessonContent,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
