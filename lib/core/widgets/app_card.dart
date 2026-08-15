import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Standard AppCard implementing dual-mode elevation and smooth theme transition rules
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool isGlassDark;
  final double borderRadius;
  final Color? customColor;
  final Border? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.isGlassDark = false,
    this.borderRadius = AppTheme.radiusMedium,
    this.customColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    List<BoxShadow>? shadows;
    Border? border;

    if (isGlassDark) {
      backgroundColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceInverse;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )
      ];
    } else if (customColor != null) {
      backgroundColor = customColor!;
    } else if (isDark) {
      backgroundColor = AppColors.darkSurface;
      shadows = null; // No drop shadows in dark mode per design spec
      border = customBorder ?? Border.all(color: AppColors.darkDivider, width: 0.8);
    } else {
      backgroundColor = AppColors.lightSurface;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )
      ];
      border = customBorder ?? Border.all(color: AppColors.lightDivider, width: 0.8);
    }

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return cardContent;
  }
}
