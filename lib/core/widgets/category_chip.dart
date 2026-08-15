import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Event Category Chip with mandatory icon pairing and dual-mode color palettes
class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onSelected,
    this.fontSize = 12,
    this.iconSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.memory_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'sports':
        return Icons.emoji_events_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'workshop':
        return Icons.handyman_rounded;
      case 'conference':
        return Icons.record_voice_over_rounded;
      case 'community':
        return Icons.groups_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  static String formatCategoryName(String category) {
    if (category.isEmpty) return '';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = category.toLowerCase();
    final colorPair = AppColors.categoryColors[normalized];

    Color bg;
    Color fg;

    if (colorPair != null) {
      bg = colorPair.getBg(isDark);
      fg = colorPair.getText(isDark);
    } else {
      bg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEAE7DC);
      fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }

    if (isSelected) {
      // Highlighted selected filter state
      bg = isDark ? AppColors.darkAccent : AppColors.lightAccent;
      fg = isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent;
    }

    final chipContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100), // Pill shape per design spec
        border: isSelected
            ? Border.all(
                color: isDark ? AppColors.darkAccent : AppColors.lightTextPrimary,
                width: 1.2,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getCategoryIcon(normalized),
            size: iconSize,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            formatCategoryName(category),
            style: AppTypography.manrope(
              fontSize: fontSize,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (onSelected != null) {
      return GestureDetector(
        onTap: () => onSelected!(!isSelected),
        child: chipContent,
      );
    }

    return chipContent;
  }
}
