import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  destructive,
  organizer,
}

/// Standard AppButton enforcing Signal Lime accents and consistent typography
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isDark ? AppColors.darkAccent : AppColors.lightAccent;
        fg = isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent;
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFECE4);
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case AppButtonVariant.outlined:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1.2,
        );
        break;
      case AppButtonVariant.destructive:
        bg = isDark ? AppColors.darkError : AppColors.lightError;
        fg = Colors.white;
        break;
      case AppButtonVariant.organizer:
        bg = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;
        fg = Colors.white;
        break;
    }

    if (isDisabled) {
      bg = isDark ? const Color(0xFF26241F) : const Color(0xFFE9E6DC);
      fg = isDark ? const Color(0xFF6E6C60) : const Color(0xFFA19E90);
      border = BorderSide.none;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: AppTypography.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: border,
        ),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: padding,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
