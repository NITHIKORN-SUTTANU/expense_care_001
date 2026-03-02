import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F6EF7);
  static const Color primaryVariant = Color(0xFF3A56D4);
  static const Color secondary = Color(0xFFF9A825);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF0F1117);
  static const Color onSurface = Color(0xFF374151);
  static const Color divider = Color(0xFFECECF3);
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF9CA3AF);

  static const Color darkPrimary = Color(0xFF6B8AFF);
  static const Color darkPrimaryVariant = Color(0xFF4F6EF7);
  static const Color darkSecondary = Color(0xFFFFB300);
  static const Color darkBackground = Color(0xFF0F0F17);
  static const Color darkSurface = Color(0xFF17171F);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkWarning = Color(0xFFFFA726);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnBackground = Color(0xFFEAEAF4);
  static const Color darkOnSurface = Color(0xFFB0B8D9);
  static const Color darkDivider = Color(0xFF242430);
  static const Color darkNavBackground = Color(0xFF17171F);
  static const Color darkMuted = Color(0xFF5A5F7A);

  static const Color catFood = Color(0xFFFF6B6B);
  static const Color catTransport = Color(0xFF4ECDC4);
  static const Color catHousing = Color(0xFF4F6EF7);
  static const Color catHealth = Color(0xFF34D399);
  static const Color catShopping = Color(0xFFA78BFA);
  static const Color catEntertainment = Color(0xFFF59E0B);
  static const Color catEducation = Color(0xFF06B6D4);
  static const Color catWork = Color(0xFF6366F1);
  static const Color catTravel = Color(0xFFFB8C00);
  static const Color catUtilities = Color(0xFF64748B);
  static const Color catGifts = Color(0xFFEC4899);
  static const Color catOther = Color(0xFF8B90A7);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Soft primary glow for logo / hero elements
  static List<BoxShadow> primaryGlow(Color primary) => [
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
