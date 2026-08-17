import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Animated Number Counter with smooth spring easing
class AnimatedMetricCounter extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final TextStyle? textStyle;
  final Duration duration;

  const AnimatedMetricCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.textStyle,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutQuad,
      builder: (context, val, child) {
        final formatted = value is int
            ? val.toInt().toString()
            : val.toStringAsFixed(1);
        return Text(
          '$prefix$formatted$suffix',
          style: textStyle,
        );
      },
    );
  }
}

/// Data class for Bar Chart items
class BarChartDataPoint {
  final String label;
  final double value;
  final Color? color;
  final String? tooltip;

  const BarChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.tooltip,
  });
}

/// Modern Animated Bar Chart with gradient columns and labels
class ModernAnimatedBarChart extends StatefulWidget {
  final List<BarChartDataPoint> data;
  final double height;
  final Color? primaryBarColor;
  final Color? secondaryBarColor;
  final String? yAxisSuffix;

  const ModernAnimatedBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.primaryBarColor,
    this.secondaryBarColor,
    this.yAxisSuffix,
  });

  @override
  State<ModernAnimatedBarChart> createState() => _ModernAnimatedBarChartState();
}

class _ModernAnimatedBarChartState extends State<ModernAnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ModernAnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDataEqual(oldWidget.data, widget.data)) {
      _controller.reset();
      _controller.forward();
    }
  }

  bool _isDataEqual(List<BarChartDataPoint> a, List<BarChartDataPoint> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].label != b[i].label || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.primaryBarColor ??
        (isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent);
    final secondaryColor = widget.secondaryBarColor ??
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6));

    final maxValue = widget.data.isEmpty
        ? 1.0
        : widget.data.map((d) => d.value).reduce(math.max);
    final safeMax = maxValue > 0 ? maxValue : 1.0;

    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No chart data available',
            style: AppTypography.manrope(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.data.length, (index) {
                    final item = widget.data[index];
                    final barHeightFactor = (item.value / safeMax) * _animation.value;
                    final isHovered = _hoveredIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _hoveredIndex = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Top value indicator
                              if (item.value > 0)
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: _animation.value > 0.6 ? 1.0 : 0.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: isHovered
                                        ? BoxDecoration(
                                            color: isDark ? const Color(0xFF2D3748) : primaryColor,
                                            borderRadius: BorderRadius.circular(5),
                                            border: isDark ? Border.all(color: const Color(0xFF4A5568), width: 1) : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Text(
                                      '${item.value.toInt()}${widget.yAxisSuffix ?? ""}',
                                      style: AppTypography.manrope(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isHovered
                                            ? Colors.white
                                            : (isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                              // Bar Body
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: barHeightFactor.clamp(0.04, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          item.color ?? secondaryColor.withValues(alpha: 0.7),
                                          item.color ?? primaryColor,
                                        ],
                                      ),
                                      boxShadow: isHovered
                                          ? [
                                              BoxShadow(
                                                color: (isDark ? const Color(0xFF6366F1) : primaryColor).withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                offset: const Offset(0, -2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // X-Axis Category Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.data.length, (index) {
              final item = widget.data[index];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.manrope(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Data class for Donut Chart segments
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Animated Donut / Radial Ring Chart with center stat
class ModernAnimatedDonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final String centerTitle;
  final String centerSubtitle;

  const ModernAnimatedDonutChart({
    super.key,
    required this.segments,
    this.size = 180,
    this.strokeWidth = 18,
    required this.centerTitle,
    required this.centerSubtitle,
  });

  @override
  State<ModernAnimatedDonutChart> createState() => _ModernAnimatedDonutChartState();
}

class _ModernAnimatedDonutChartState extends State<ModernAnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ModernAnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSegmentsEqual(oldWidget.segments, widget.segments)) {
      _controller.reset();
      _controller.forward();
    }
  }

  bool _isSegmentsEqual(List<DonutSegment> a, List<DonutSegment> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].label != b[i].label || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.segments.isEmpty
        ? 1.0
        : widget.segments.map((s) => s.value).reduce((a, b) => a + b);
    final safeTotal = total > 0 ? total : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _DonutChartPainter(
                      segments: widget.segments,
                      total: safeTotal,
                      progress: _animation.value,
                      strokeWidth: widget.strokeWidth,
                      isDark: isDark,
                    ),
                  );
                },
              ),
              // Center Metric Badge
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerTitle,
                    style: AppTypography.frauncesSignature(
                      fontSize: 24,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    widget.centerSubtitle,
                    style: AppTypography.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend Pills
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.segments.map((seg) {
            final pct = ((seg.value / safeTotal) * 100).toStringAsFixed(0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${seg.label} ($pct%)',
                  style: AppTypography.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double total;
  final double progress;
  final double strokeWidth;
  final bool isDark;

  _DonutChartPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E222D) : const Color(0xFFE8E5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (segments.isEmpty) return;

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = (seg.value / total) * 2 * math.pi * progress;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Inset slightly to show separation
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.04,
        math.max(0, sweepAngle - 0.08),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}
