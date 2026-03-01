import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        primaryVariant: AppColors.primaryVariant,
        background: AppColors.background,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onBackground: AppColors.onBackground,
        onSurface: AppColors.onSurface,
        divider: AppColors.divider,
        error: AppColors.error,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        primaryVariant: AppColors.darkPrimaryVariant,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.darkOnPrimary,
        onBackground: AppColors.darkOnBackground,
        onSurface: AppColors.darkOnSurface,
        divider: AppColors.darkDivider,
        error: AppColors.darkError,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color primaryVariant,
    required Color background,
    required Color surface,
    required Color onPrimary,
    required Color onBackground,
    required Color onSurface,
    required Color divider,
    required Color error,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: isDark ? AppColors.darkSecondary : AppColors.secondary,
        onSecondary: Colors.black,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onBackground,
        ),
        iconTheme: IconThemeData(color: onBackground),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkNavBackground : AppColors.navBackground,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? AppColors.darkMuted : AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        errorMaxLines: 3,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: isDark ? AppColors.darkMuted : AppColors.muted,
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.5)
              : divider,
        ),
      ),
    );
  }
}
