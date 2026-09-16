import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary Accent - Calm & Trustworthy Teal/Blue
  static const Color primary = Color(0xFF0F766E); // Deep Teal
  static const Color primaryContainer = Color(0xFFE6F4F1);
  static const Color onPrimary = Colors.white;

  // Backgrounds & Neutral Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Slate-50 off-white
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const Color border = Color(0xFFE2E8F0); // Slate-200

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900 (High contrast)
  static const Color textSecondary = Color(0xFF475569); // Slate-600
  static const Color textMuted = Color(0xFF64748B); // Slate-500

  // Reserved ONLY for Emergency/Alert/SOS states
  static const Color sosRed = Color(0xFFDC2626); // Red-600
  static const Color sosRedBg = Color(0xFFFEF2F2); // Red-50
  static const Color sosRedBorder = Color(0xFFFCA5A5); // Red-300

  // Status & Classification Badges
  static const Color safeGreen = Color(0xFF166534); // Green-800
  static const Color safeGreenBg = Color(0xFFF0FDF4); // Green-50
  static const Color safeGreenBorder = Color(0xFF86EFAC);

  static const Color uncertainYellow = Color(0xFF854D0E); // Yellow-800
  static const Color uncertainYellowBg = Color(0xFFFEFCE8); // Yellow-50
  static const Color uncertainYellowBorder = Color(0xFFFDE047);

  static const Color concerningOrange = Color(0xFF9A3412); // Orange-800
  static const Color concerningOrangeBg = Color(0xFFFFEDD5); // Orange-50
  static const Color concerningOrangeBorder = Color(0xFFFDBA74);
}
