import 'package:flutter/material.dart';

/// Control-Room / Dispatch Console Color Tokens
class AppColors {
  // Primary Backgrounds
  static const Color background = Color(0xFFF4F5F7); // Cool light gray (NOT white, NOT off-white cream)
  static const Color surface = Color(0xFFFFFFFF); // White cards/surface
  static const Color surfaceVariant = Color(0xFFEDF0F5); // Low-contrast dispatch container
  static const Color border = Color(0xFFD8DCE3); // Solid divider / card border
  static const Color hairlineBorder = Color(0x1A0E1A2B); // 10% opacity navy hairline

  // Primary Typography
  static const Color textPrimary = Color(0xFF0E1A2B); // Deep navy-charcoal, near-black
  static const Color textSecondary = Color(0xFF4A5568); // Slate gray
  static const Color textMuted = Color(0xFF718096);

  // Brand & Action Accents
  static const Color primary = Color(0xFF14304D); // Deep Navy Primary Action
  static const Color primaryContainer = Color(0xFFE2E8F0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color accentSecondary = Color(0xFF3B6E91); // Steel blue

  // WARNING State ONLY (Uncertain / Degraded)
  static const Color warningAmber = Color(0xFFC77A1F); // Amber (NOT yellow)
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFCD34D);

  // DANGER / SOS State ONLY (Escalation, Alerts)
  static const Color sosRed = Color(0xFFB3261E); // Deep Red (NOT bright/cartoonish)
  static const Color sosRedBg = Color(0xFFFEF2F2);
  static const Color sosRedBorder = Color(0xFFFCA5A5);

  // SUCCESS / Safe State ONLY (Used sparingly, confirmation only)
  static const Color safeGreen = Color(0xFF1E6B4F); // Deep Forest Green (NOT mint/teal)
  static const Color safeGreenBg = Color(0xFFF0FDF4);
  static const Color safeGreenBorder = Color(0xFF86EFAC);

  // Deprecated color alias mapping for clean compile compatibility
  static const Color cyanAccent = Color(0xFF3B6E91);
  static const Color uncertainYellow = Color(0xFFC77A1F);
  static const Color uncertainYellowBg = Color(0xFFFFFBEB);
  static const Color uncertainYellowBorder = Color(0xFFFCD34D);
}
