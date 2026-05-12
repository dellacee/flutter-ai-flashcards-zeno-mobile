import 'package:flutter/material.dart';

/// Brand and semantic color tokens used to derive themes.
class AppColors {
  AppColors._();

  // Brand seed (indigo-500). Material 3 derives the rest from this.
  static const Color seed = Color(0xFF6366F1);

  // Surface tokens — light
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurface = Color(0xFF0F172A);

  // Surface tokens — dark
  static const Color darkSurface = Color(0xFF0B0F19);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkOnSurface = Color(0xFFE2E8F0);

  // Status semantic colors (colorblind-safe pairings)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
