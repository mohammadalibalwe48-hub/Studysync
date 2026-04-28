import 'package:flutter/material.dart';

/// Represents a study subject (e.g. Physics, Chemistry).
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
}
