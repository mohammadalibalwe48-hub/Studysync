import 'package:flutter/material.dart';

/// Small chip-style badge that shows the student's current daily streak.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFEA8A1F),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$days day streak',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A4B12),
            ),
          ),
        ],
      ),
    );
  }
}
