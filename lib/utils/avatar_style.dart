import 'package:flutter/material.dart';

class AvatarStyle {
  /// 🎨 Premium color palette (carefully selected)
  /// Soft, elegant, and suitable for family & memory apps
  static const List<Color> _palette = [
    Color(0xFF6A5AE0), // Soft Purple
    Color(0xFF3B82F6), // Calm Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFF22C55E), // Green
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
    Color(0xFFEAB308), // Warm Yellow
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEF4444), // Soft Red
    Color(0xFF64748B), // Slate
    Color(0xFF9333EA), // Deep Purple
    Color(0xFF2563EB), // Royal Blue
  ];

  /// 🔒 Stable color per child (based on ID, not name)
  static Color colorFor(String childId) {
    final hash = childId.hashCode.abs();
    return _palette[hash % _palette.length];
  }

  /// 🔠 Avatar initial
  static String initial(String name) {
    if (name.trim().isEmpty) return '?';
    return name.trim().characters.first.toUpperCase();
  }
}
