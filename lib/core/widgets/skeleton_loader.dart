import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shimmer effect controller and animation wrapper
class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E222D) : const Color(0xFFE8E5DD);
    final highlightColor = isDark ? const Color(0xFF2E3445) : const Color(0xFFF7F5F0);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              if (bounds.isEmpty) return const LinearGradient(colors: [Colors.transparent, Colors.transparent]).createShader(bounds);
              final progress = _animation.value;
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: [
                  (progress - 0.3).clamp(0.0, 1.0),
                  progress.clamp(0.0, 1.0),
                  (progress + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: widget.child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Primitive skeleton shape with rounded corners
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? customShape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.customShape,
  });

  const AppSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        customShape = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF232733) : const Color(0xFFE2DFD6);

    return Container(
      width: width,
      height: height,
      decoration: customShape == null
          ? BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
            )
          : ShapeDecoration(
              color: color,
              shape: customShape!,
            ),
    );
  }
}

/// Event Card Skeleton placeholder for instant visual loading
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner Skeleton
            const ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: AppSkeleton(
                width: double.infinity,
                height: 175,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag & Date badge skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppSkeleton(width: 80, height: 22, borderRadius: 12),
                      AppSkeleton(width: 90, height: 18, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title skeleton
                  const AppSkeleton(width: double.infinity, height: 20, borderRadius: 6),
                  const SizedBox(height: 8),
                  const AppSkeleton(width: 200, height: 16, borderRadius: 6),
                  const SizedBox(height: 16),
                  // Location and capacity skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppSkeleton(width: 130, height: 16, borderRadius: 6),
                      AppSkeleton(width: 70, height: 16, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of multiple event card skeletons
class EventListSkeleton extends StatelessWidget {
  final int itemCount;

  const EventListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (_, __) => const EventCardSkeleton(),
    );
  }
}

/// Stat Card Skeleton placeholder for dashboard analytics
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                AppSkeleton(width: 36, height: 36, borderRadius: 10),
                AppSkeleton(width: 24, height: 16, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 16),
            const AppSkeleton(width: 60, height: 28, borderRadius: 6),
            const SizedBox(height: 6),
            const AppSkeleton(width: 100, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
