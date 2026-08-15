import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Ultra-modern, branded empty state view with pulsing ambient halo and action support
class EmptyStateView extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final bool isCompact;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 48,
    this.isCompact = false,
  });

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 16.0 : 32.0,
          vertical: widget.isCompact ? 20.0 : 40.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ambient Pulsing Glow + Icon Container
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: widget.iconSize * 2.2,
                        height: widget.iconSize * 2.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
                              accentColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  padding: EdgeInsets.all(widget.isCompact ? 14 : 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFECE4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.isCompact ? 14 : 22),
            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.frauncesSignature(
                fontSize: widget.isCompact ? 18 : 22,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            // Message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: AppTypography.manrope(
                  fontSize: widget.isCompact ? 12.5 : 14,
                  fontWeight: FontWeight.w400,
                  color: secondaryTextColor,
                  height: 1.45,
                ),
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              SizedBox(height: widget.isCompact ? 16 : 24),
              SizedBox(
                width: 190,
                child: AppButton(
                  text: widget.actionLabel!,
                  onPressed: widget.onAction!,
                  height: widget.isCompact ? 40 : 46,
                  icon: Icons.refresh_rounded,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
