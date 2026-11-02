import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette (mirrors theme.config.js of the Expo app).
class AppColors {
  AppColors._();

  static const primary = Color(0xFFD4AF37); // gold
  static const darkGreen = Color(0xFF07352B);
  static const deepGreen = Color(0xFF041D18);
  static const cream = Color(0xFFFFF9ED);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF8F8F8);
  static const foreground = Color(0xFF1A1A1A);
  static const muted = Color(0xFF8A8A8A);
  static const border = Color(0xFFE8E8E8);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);

  static const goldBg = Color(0xFFFFF9E6);
  static const goldBorder = Color(0xFFF5D766);
  static const goldText = Color(0xFF5A460A);
}

ThemeData buildTheme(String lang) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkGreen,
      primary: AppColors.darkGreen,
      secondary: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  final textTheme = lang == 'ar'
      ? GoogleFonts.cairoTextTheme(base.textTheme)
      : GoogleFonts.interTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme.apply(bodyColor: AppColors.foreground, displayColor: AppColors.foreground),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.foreground,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.6, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
