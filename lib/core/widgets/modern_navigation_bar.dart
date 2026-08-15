import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ModernNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;

  const ModernNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Ultra-modern floating glassmorphic bottom navigation bar with animated pill indicators
class ModernFloatingNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items;
  final Color? activeColor;

  const ModernFloatingNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = activeColor ??
        (isDark ? AppColors.darkAccent : AppColors.lightAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141721).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Active Pill with Icon & Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 16 : 8,
                                vertical: isSelected ? 4 : 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withValues(alpha: isDark ? 0.22 : 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: accent.withValues(alpha: isDark ? 0.4 : 0.25),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? accent
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              ),
                            ),
                            // Badge Pill
                            if (item.badgeCount > 0)
                              Positioned(
                                top: -3,
                                right: isSelected ? 8 : 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkError : AppColors.lightError,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? AppColors.darkError : AppColors.lightError)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: AppTypography.manrope(
                            fontSize: isSelected ? 11 : 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
