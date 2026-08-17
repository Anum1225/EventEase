import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: defaultFallback)
          : defaultFallback;
    }

    Widget imageWidget;

    // 1. Base64 Data URI handling
    if (url.startsWith('data:image/')) {
      try {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = url.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data);
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => defaultFallback,
          );
        } else {
          imageWidget = defaultFallback;
        }
      } catch (_) {
        imageWidget = defaultFallback;
      }
    }
    // 2. HTTP/HTTPS Network URL handling
    else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
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
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    }
    // 3. Local File Path handling
    else {
      if (kIsWeb) {
        imageWidget = defaultFallback;
      } else {
        try {
          final file = File(url);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => defaultFallback,
            );
          } else {
            imageWidget = defaultFallback;
          }
        } catch (_) {
          imageWidget = defaultFallback;
        }
      }
    }

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: imageWidget)
        : imageWidget;
  }
}
