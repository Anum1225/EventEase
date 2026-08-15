import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ultra-resilient, GPU-optimized network image widget for Flutter Web CanvasKit and Mobile
/// Completely prevents WebGL texImage2D empty texture crashes and provides smooth transitions.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallbackWidget;
  final Widget? placeholderWidget;
  final IconData fallbackIcon;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackWidget,
    this.placeholderWidget,
    this.fallbackIcon = Icons.event_seat_rounded,
  });

  bool get _isValidUrl {
    if (imageUrl == null) return false;
    final url = imageUrl!.trim();
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultFallback = fallbackWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E2230), const Color(0xFF151822)]
                  : [const Color(0xFFEBE8DC), const Color(0xFFDED9CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              fallbackIcon,
              size: (height != null && height! < 60) ? 22 : 36,
              color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.6) : AppColors.lightTextSecondary.withValues(alpha: 0.6),
            ),
          ),
        );

    if (!_isValidUrl) {
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: defaultFallback)
          : defaultFallback;
    }

    final imageWidget = Image.network(
      imageUrl!.trim(),
      width: width,
      height: height,
      fit: fit,
      // Target memory dimensions to prevent WebGL GPU texture exhaustion
      cacheWidth: width != null && width!.isFinite ? (width! * 2).round() : null,
      cacheHeight: height != null && height!.isFinite ? (height! * 2).round() : null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholderWidget ??
            Container(
              width: width,
              height: height,
              color: isDark ? const Color(0xFF222634) : const Color(0xFFE2DFD4),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return defaultFallback;
      },
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: imageWidget)
        : imageWidget;
  }
}
