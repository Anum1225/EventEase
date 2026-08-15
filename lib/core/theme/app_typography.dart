import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// EventEase typography configuration with resilient web/offline font fallbacks
class AppTypography {
  AppTypography._();

  static const List<String> _fontFallbacks = [
    'Manrope',
    'Roboto',
    'Segoe UI',
    '-apple-system',
    'BlinkMacSystemFont',
    'Arial',
    'sans-serif',
  ];

  static const List<String> _serifFallbacks = [
    'Fraunces',
    'Georgia',
    'Cambria',
    'Times New Roman',
    'serif',
  ];

  static final TextStyle _baseManrope = () {
    try {
      return GoogleFonts.manrope(
        fontWeight: FontWeight.w400,
        height: 1.25,
      );
    } catch (_) {
      return const TextStyle(
        fontFamilyFallback: _fontFallbacks,
        fontWeight: FontWeight.w400,
        height: 1.25,
      );
    }
  }();

  static final TextStyle _baseFraunces = () {
    try {
      return GoogleFonts.fraunces(
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.25,
          fontFamilyFallback: _serifFallbacks,
        ),
      );
    } catch (_) {
      return const TextStyle(
        fontFamilyFallback: _serifFallbacks,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 1.25,
      );
    }
  }();

  /// Primary UI Family: Manrope with fallback (Fast copyWith)
  static TextStyle manrope({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return _baseManrope.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height ?? 1.25,
      letterSpacing: letterSpacing,
    );
  }

  /// Signature Serif/Italic Family: Fraunces with fallback (Fast copyWith)
  static TextStyle frauncesSignature({
    double fontSize = 28,
    Color? color,
    double? height,
  }) {
    return _baseFraunces.copyWith(
      fontSize: fontSize,
      color: color,
      height: height ?? 1.25,
    );
  }

  static final TextTheme _lightTextTheme = _buildTextTheme(false);
  static final TextTheme _darkTextTheme = _buildTextTheme(true);

  /// Generates the standard TextTheme scale for ThemeData (Instant static lookup)
  static TextTheme createTextTheme(bool isDark) => isDark ? _darkTextTheme : _lightTextTheme;

  static TextTheme _buildTextTheme(bool isDark) {
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      // Display: QR Pass event title only (Fraunces italic)
      displayLarge: frauncesSignature(fontSize: 32, color: primaryColor),
      displayMedium: frauncesSignature(fontSize: 28, color: primaryColor),
      displaySmall: frauncesSignature(fontSize: 24, color: primaryColor),

      // Headline: Screen titles (Manrope 700)
      headlineLarge: manrope(fontSize: 28, fontWeight: FontWeight.w700, color: primaryColor),
      headlineMedium: manrope(fontSize: 24, fontWeight: FontWeight.w700, color: primaryColor),
      headlineSmall: manrope(fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor),

      // Title: Card titles, section headers (Manrope 600)
      titleLarge: manrope(fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor),
      titleMedium: manrope(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
      titleSmall: manrope(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),

      // Body: Body copy, descriptions (Manrope 400)
      bodyLarge: manrope(fontSize: 16, fontWeight: FontWeight.w400, color: primaryColor),
      bodyMedium: manrope(fontSize: 15, fontWeight: FontWeight.w400, color: primaryColor),
      bodySmall: manrope(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryColor),

      // Label: Buttons, chips, captions (Manrope 500)
      labelLarge: manrope(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
      labelMedium: manrope(fontSize: 13, fontWeight: FontWeight.w500, color: secondaryColor),
      labelSmall: manrope(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryColor),
    );
  }
}
