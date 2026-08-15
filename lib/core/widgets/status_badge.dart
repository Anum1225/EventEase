import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Status Badge with mandatory icon pairing and distinct visual treatments
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.iconSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.toLowerCase();

    Color bg;
    Color fg;
    IconData icon;
    String label;
    bool strikethrough = false;

    switch (normalized) {
      case 'pending_approval':
      case 'pending':
        bg = isDark ? const Color(0xFF382C14) : const Color(0xFFFFF2D4);
        fg = isDark ? AppColors.darkWarning : AppColors.lightWarning;
        icon = Icons.schedule_rounded;
        label = 'Pending Approval';
        break;
      case 'approved':
      case 'registered':
      case 'attended':
        bg = isDark ? const Color(0xFF163326) : const Color(0xFFDEF5E7);
        fg = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
        icon = Icons.check_circle_rounded;
        label = normalized == 'attended'
            ? 'Checked In'
            : normalized == 'registered'
                ? 'Registered'
                : 'Approved';
        break;
      case 'rejected':
        bg = isDark ? const Color(0xFF381B18) : const Color(0xFFFFE8E6);
        fg = isDark ? AppColors.darkError : AppColors.lightError;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      case 'cancelled':
        bg = isDark ? const Color(0xFF281E1C) : const Color(0xFFF5E8E6);
        fg = isDark ? AppColors.darkError : AppColors.lightError;
        icon = Icons.block_rounded;
        label = 'Cancelled';
        strikethrough = true;
        break;
      case 'completed':
        bg = isDark ? const Color(0xFF24221D) : const Color(0xFFEDEAE1);
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        icon = Icons.flag_rounded;
        label = 'Completed';
        break;
      case 'deactivated':
        bg = isDark ? const Color(0xFF381B18) : const Color(0xFFFFE8E6);
        fg = isDark ? AppColors.darkError : AppColors.lightError;
        icon = Icons.person_off_rounded;
        label = 'Deactivated';
        break;
      case 'active':
        bg = isDark ? const Color(0xFF163326) : const Color(0xFFDEF5E7);
        fg = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
        icon = Icons.verified_user_rounded;
        label = 'Active';
        break;
      default:
        bg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE9E6DC);
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        icon = Icons.info_outline_rounded;
        label = status;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: fg,
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: AppTypography.manrope(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ).copyWith(
              decoration: strikethrough ? TextDecoration.lineThrough : null,
              decorationColor: fg,
            ),
          ),
        ],
      ),
    );
  }
}
