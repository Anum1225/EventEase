import 'package:flutter/material.dart';

/// EventEase design system color tokens grounded in 06_DESIGN_SYSTEM_REFERENCE.md
class AppColors {
  AppColors._();

  // --- Light Mode Palette ---
  static const Color lightBg = Color(0xFFF7F6F1);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceInverse = Color(0xEB161512); // ~92% dark glass
  static const Color lightTextPrimary = Color(0xFF0F0E0B);
  static const Color lightTextSecondary = Color(0xFF555246);
  static const Color lightDivider = Color(0xFFE4E0D5);
  static const Color lightAccent = Color(0xFFC6F135); // Signal Lime
  static const Color lightOnAccent = Color(0xFF101404);
  static const Color lightOrganizerAccent = Color(0xFF5B4DFF); // Richer Indigo
  static const Color lightAdminAccent = Color(0xFF0F0E0B);
  static const Color lightSuccess = Color(0xFF1B9E63); // Richer Verified Green
  static const Color lightWarning = Color(0xFFC77A14); // Pending Amber
  static const Color lightError = Color(0xFFD33C30); // Coral Red
  static const Color lightInfo = Color(0xFF2C6CD1);

  // --- Dark Mode Palette ---
  static const Color darkBg = Color(0xFF121110);
  static const Color darkSurface = Color(0xFF1C1B18);
  static const Color darkSurfaceElevated = Color(0xFF26241F);
  static const Color darkTextPrimary = Color(0xFFF3F1E9);
  static const Color darkTextSecondary = Color(0xFFA19E90);
  static const Color darkDivider = Color(0xFF302E28);
  static const Color darkAccent = Color(0xFFD6F566); // Brightened Lime
  static const Color darkOnAccent = Color(0xFF121110);
  static const Color darkOrganizerAccent = Color(0xFF9188FF); // Brightened Indigo
  static const Color darkAdminAccent = Color(0xFFF3F1E9);
  static const Color darkSuccess = Color(0xFF3FCB8C);
  static const Color darkWarning = Color(0xFFEBA83F);
  static const Color darkError = Color(0xFFEA6B60);
  static const Color darkInfo = Color(0xFF6FA0F0);

  // --- Category Color Pairs (Light / Dark) ---
  static const Map<String, CategoryColorPair> categoryColors = {
    'technology': CategoryColorPair(
      lightBg: Color(0xFFE7EEFF),
      lightText: Color(0xFF2E4CC4),
      darkBg: Color(0xFF212A45),
      darkText: Color(0xFF8FA5FF),
      iconName: 'circuit',
    ),
    'education': CategoryColorPair(
      lightBg: Color(0xFFFFF2D4),
      lightText: Color(0xFF8A5B00),
      darkBg: Color(0xFF382C14),
      darkText: Color(0xFFF0C674),
      iconName: 'school',
    ),
    'sports': CategoryColorPair(
      lightBg: Color(0xFFDEF5E7),
      lightText: Color(0xFF0F7A45),
      darkBg: Color(0xFF163326),
      darkText: Color(0xFF5FD696),
      iconName: 'sports_soccer',
    ),
    'music': CategoryColorPair(
      lightBg: Color(0xFFF4E1FF),
      lightText: Color(0xFF7A2EBF),
      darkBg: Color(0xFF2C1F38),
      darkText: Color(0xFFC68FF5),
      iconName: 'music_note',
    ),
    'business': CategoryColorPair(
      lightBg: Color(0xFFE2E8EE),
      lightText: Color(0xFF2E4A5E),
      darkBg: Color(0xFF222A30),
      darkText: Color(0xFF8FB0C9),
      iconName: 'business_center',
    ),
    'workshop': CategoryColorPair(
      lightBg: Color(0xFFFFE7DA),
      lightText: Color(0xFFB34700),
      darkBg: Color(0xFF382318),
      darkText: Color(0xFFF0956B),
      iconName: 'build',
    ),
    'conference': CategoryColorPair(
      lightBg: Color(0xFFE7E1FF),
      lightText: Color(0xFF4B2EBF),
      darkBg: Color(0xFF251F3D),
      darkText: Color(0xFFA88FF5),
      iconName: 'record_voice_over',
    ),
    'community': CategoryColorPair(
      lightBg: Color(0xFFFFE2EA),
      lightText: Color(0xFFB32E5C),
      darkBg: Color(0xFF381E27),
      darkText: Color(0xFFF08FB0),
      iconName: 'groups',
    ),
  };
}

/// Holds dual-mode colors and associated icon name for event categories
class CategoryColorPair {
  final Color lightBg;
  final Color lightText;
  final Color darkBg;
  final Color darkText;
  final String iconName;

  const CategoryColorPair({
    required this.lightBg,
    required this.lightText,
    required this.darkBg,
    required this.darkText,
    required this.iconName,
  });

  Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  Color getText(bool isDark) => isDark ? darkText : lightText;
}

/// Custom ThemeExtension providing role accents, glows, and surface inversions
@immutable
class AppCustomThemeExtension extends ThemeExtension<AppCustomThemeExtension> {
  final Color organizerAccent;
  final Color adminAccent;
  final Color surfaceInverse;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color glowAccent;

  const AppCustomThemeExtension({
    required this.organizerAccent,
    required this.adminAccent,
    required this.surfaceInverse,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.glowAccent,
  });

  static const light = AppCustomThemeExtension(
    organizerAccent: AppColors.lightOrganizerAccent,
    adminAccent: AppColors.lightAdminAccent,
    surfaceInverse: AppColors.lightSurfaceInverse,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    error: AppColors.lightError,
    info: AppColors.lightInfo,
    glowAccent: Color(0x2EC6F135),
  );

  static const dark = AppCustomThemeExtension(
    organizerAccent: AppColors.darkOrganizerAccent,
    adminAccent: AppColors.darkAdminAccent,
    surfaceInverse: AppColors.darkSurface,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    error: AppColors.darkError,
    info: AppColors.darkInfo,
    glowAccent: Color(0x2ED6F566),
  );

  @override
  AppCustomThemeExtension copyWith({
    Color? organizerAccent,
    Color? adminAccent,
    Color? surfaceInverse,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? glowAccent,
  }) {
    return AppCustomThemeExtension(
      organizerAccent: organizerAccent ?? this.organizerAccent,
      adminAccent: adminAccent ?? this.adminAccent,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      glowAccent: glowAccent ?? this.glowAccent,
    );
  }

  @override
  AppCustomThemeExtension lerp(ThemeExtension<AppCustomThemeExtension>? other, double t) {
    if (other is! AppCustomThemeExtension) return this;
    return AppCustomThemeExtension(
      organizerAccent: Color.lerp(organizerAccent, other.organizerAccent, t)!,
      adminAccent: Color.lerp(adminAccent, other.adminAccent, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      glowAccent: Color.lerp(glowAccent, other.glowAccent, t)!,
    );
  }
}
