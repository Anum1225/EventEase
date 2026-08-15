import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// WCAG 2.1 Contrast Ratio Calculator and Validator
class ContrastChecker {
  ContrastChecker._();

  /// Calculates relative luminance according to WCAG 2.1 specs
  static double getRelativeLuminance(Color color) {
    double transform(double value) {
      if (value <= 0.03928) {
        return value / 12.92;
      } else {
        return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
      }
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates contrast ratio between two colors (range: 1.0 to 21.0)
  static double getContrastRatio(Color foreground, Color background) {
    final lum1 = getRelativeLuminance(foreground);
    final lum2 = getRelativeLuminance(background);

    final lighter = math.max(lum1, lum2);
    final darker = math.min(lum1, lum2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Verifies whether the pair meets WCAG AA (4.5:1 for normal text, 3.0:1 for large text/graphical UI)
  static bool meetsWcagAa(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return ratio >= (isLargeText ? 3.0 : 4.5);
  }

  /// Audit report for all primary theme pairs
  static Map<String, double> auditThemePairings() {
    return {
      'Light Text on Light Bg': getContrastRatio(AppColors.lightTextPrimary, AppColors.lightBg),
      'Light Text Secondary on Light Bg': getContrastRatio(AppColors.lightTextSecondary, AppColors.lightBg),
      'Light On-Accent on Light Accent': getContrastRatio(AppColors.lightOnAccent, AppColors.lightAccent),
      'Dark Text on Dark Bg': getContrastRatio(AppColors.darkTextPrimary, AppColors.darkBg),
      'Dark Text Secondary on Dark Bg': getContrastRatio(AppColors.darkTextSecondary, AppColors.darkBg),
      'Dark On-Accent on Dark Accent': getContrastRatio(AppColors.darkOnAccent, AppColors.darkAccent),
      'Light Success on Light Bg': getContrastRatio(AppColors.lightSuccess, AppColors.lightBg),
      'Dark Success on Dark Bg': getContrastRatio(AppColors.darkSuccess, AppColors.darkBg),
      'Light Error on Light Bg': getContrastRatio(AppColors.lightError, AppColors.lightBg),
      'Dark Error on Dark Bg': getContrastRatio(AppColors.darkError, AppColors.darkBg),
    };
  }
}
