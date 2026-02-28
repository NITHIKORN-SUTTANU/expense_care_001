import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 32,
      height: 40 / 32,
      color: color ?? AppColors.onBackground);

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 24,
      height: 32 / 24,
      color: color ?? AppColors.onBackground);

  static TextStyle titleLarge({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      height: 28 / 20,
      color: color ?? AppColors.onBackground);

  static TextStyle titleMedium({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 24 / 16,
      color: color ?? AppColors.onBackground);

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 24 / 16,
      color: color ?? AppColors.onBackground);

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 20 / 14,
      color: color ?? AppColors.onSurface);

  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 20 / 14,
      color: color ?? AppColors.onBackground);

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
      fontWeight: FontWeight.w500,
      fontSize: 11,
      height: 16 / 11,
      color: color ?? AppColors.muted);
}
