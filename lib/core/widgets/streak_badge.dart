import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';

/// Compact pill that shows the student's daily streak.
///
/// The flame is the only place in the app that uses amber — a deliberate
/// signal so streak status pops out of the indigo-dominant palette.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.warm.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.local_fire_department_rounded,
            color: palette.warm,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            '$days يوم',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.warm,
            ),
          ),
        ],
      ),
    );
  }
}
