import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized application theme.
/// Tuned for an enterprise ERP/POS product with an Arabic RTL layout
/// and a modern dark-navy + gold accent identity suited for the
/// Mauritania commercial market.
class AppTheme {
  AppTheme._();

  // ----- Brand palette -----
  static const Color primary = Color(0xFF0B1F3A); // Deep navy
  static const Color primaryDark = Color(0xFF06122A);
  static const Color primaryLight = Color(0xFF1E3A66);

  static const Color accent = Color(0xFFD4A24E); // Refined gold
  static const Color accentDark = Color(0xFFB9862E);

  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFEEF1F7);

  static const Color textPrimary = Color(0xFF0F1B2D);
  static const Color textSecondary = Color(0xFF5A6B85);
  static const Color divider = Color(0xFFE2E7EF);

  // Semantic colors
  static const Color success = Color(0xFF1F9D63);
  static const Color warning = Color(0xFFE0A33E);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF2E7DD2);

  // Role tints
  static const Color retailTint = Color(0xFF1E6FBA);
  static const Color wholesaleTint = Color(0xFF6B4FBB);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Color(0xFF1A1305),
          surface: surface,
          onSurface: textPrimary,
          error: danger,
          surfaceContainerHighest: surfaceAlt,
        ),
        fontFamily: GoogleFonts.cairo().fontFamily,
        textTheme: GoogleFonts.cairoTextTheme().copyWith(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            height: 1.2,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            color: textPrimary,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            color: textSecondary,
            height: 1.5,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: divider, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceAlt,
          labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
        ),
      );
}

/// Extension helpers for working with the brand palette directly on
/// [BuildContext], so widgets stay readable.
extension BrandColors on BuildContext {
  Color get primaryColor => AppTheme.primary;
  Color get accentColor => AppTheme.accent;
  Color get surfaceColor => AppTheme.surface;
  Color get surfaceAltColor => AppTheme.surfaceAlt;
  Color get textPrimaryColor => AppTheme.textPrimary;
  Color get textSecondaryColor => AppTheme.textSecondary;
  Color get successColor => AppTheme.success;
  Color get warningColor => AppTheme.warning;
  Color get dangerColor => AppTheme.danger;
  Color get infoColor => AppTheme.info;
}
