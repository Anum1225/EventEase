import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';

/// The Signature Moment: Award-winning ticket-stub QR Pass card
class QRPassCard extends StatefulWidget {
  final String eventTitle;
  final String? bannerUrl;
  final DateTime? eventDate;
  final String? startTime;
  final String? location;
  final String attendeeName;
  final String qrCodePayload;
  final String registrationId;
  final bool hasAttended;
  final DateTime? checkedInAt;
  final String? category;

  const QRPassCard({
    super.key,
    required this.eventTitle,
    this.bannerUrl,
    this.eventDate,
    this.startTime,
    this.location,
    required this.attendeeName,
    required this.qrCodePayload,
    required this.registrationId,
    this.hasAttended = false,
    this.checkedInAt,
    this.category,
  });

  @override
  State<QRPassCard> createState() => _QRPassCardState();
}

class _QRPassCardState extends State<QRPassCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial Glow Source behind ticket in dark mode (content-driven)
              if (isDark)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.darkAccent.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        radius: 0.75,
                      ),
                    ),
                  ),
                ),

              // The Ticket Stub Physical Body
              PhysicalShape(
                clipper: TicketStubClipper(notchRadius: 14, notchPositionFraction: 0.58),
                color: cardBg,
                elevation: isDark ? 0 : 8,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                child: SizedBox(
                  width: math.min(MediaQuery.of(context).size.width - 48, 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Event Banner & Title Section
                      _buildTopSection(isDark, primaryTextColor, secondaryTextColor),

                      // Perforated Divider Line
                      const PerforatedDivider(),

                      // Bottom Pure-White QR Code Container Section
                      _buildBottomSection(isDark, primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
              ),

              // "CHECKED IN" Stamp Overlay
              if (widget.hasAttended)
                Positioned(
                  bottom: 90,
                  child: Transform.rotate(
                    angle: -0.22, // ~ -12.5 degrees rotation
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            .withValues(alpha: 0.12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CHECKED IN',
                            style: AppTypography.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                            ),
                          ),
                          if (widget.checkedInAt != null)
                            Text(
                              DateFormatter.formatDateTime(widget.checkedInAt),
                              style: AppTypography.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(bool isDark, Color primaryColor, Color secondaryColor) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE9E6DC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Banner Image if available
          if (widget.bannerUrl != null && widget.bannerUrl!.isNotEmpty)
            AppNetworkImage(
              imageUrl: widget.bannerUrl,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
            ),

          // Legibility Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),

          // Content Details
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.category != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.category!.toUpperCase(),
                      style: AppTypography.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightOnAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                // Signature Title: Italic Fraunces with SOFT/WONK
                Text(
                  widget.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.frauncesSignature(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFFF3F1E9)),
                    const SizedBox(width: 5),
                    Text(
                      DateFormatter.formatShortDate(widget.eventDate),
                      style: AppTypography.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF3F1E9),
                      ),
                    ),
                    if (widget.startTime != null && widget.startTime!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFF3F1E9)),
                      const SizedBox(width: 5),
                      Text(
                        widget.startTime!,
                        style: AppTypography.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF3F1E9),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDark, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guaranteed Pure-White QR Container for scanability
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, // Hard technical requirement: always pure white
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0DCD1), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: QrImageView(
              data: widget.qrCodePayload,
              version: QrVersions.auto,
              size: 190.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attendee Name & Pass Reference
          Text(
            widget.attendeeName,
            style: AppTypography.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pass ID: ${widget.registrationId.length > 12 ? widget.registrationId.substring(0, 12).toUpperCase() : widget.registrationId.toUpperCase()}',
            style: AppTypography.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Clipper creating circular ticket notches on left and right edges
class TicketStubClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchPositionFraction;

  TicketStubClipper({
    this.notchRadius = 14.0,
    this.notchPositionFraction = 0.58,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerRadius = AppTheme.radiusLarge;
    final notchCenterY = size.height * notchPositionFraction;

    // Top-Left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Top edge
    path.lineTo(size.width - cornerRadius, 0);

    // Top-Right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right edge down to notch
    path.lineTo(size.width, notchCenterY - notchRadius);

    // Right circular notch
    path.arcToPoint(
      Offset(size.width, notchCenterY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right edge down to bottom
    path.lineTo(size.width, size.height - cornerRadius);

    // Bottom-Right corner
    path.quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height);

    // Bottom edge
    path.lineTo(cornerRadius, size.height);

    // Bottom-Left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left edge up to notch
    path.lineTo(0, notchCenterY + notchRadius);

    // Left circular notch
    path.arcToPoint(
      Offset(0, notchCenterY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Left edge up to top corner
    path.lineTo(0, cornerRadius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Dashed Perforated Divider line across ticket
class PerforatedDivider extends StatelessWidget {
  final double height;
  final Color? color;

  const PerforatedDivider({super.key, this.height = 1, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = color ?? (isDark ? AppColors.darkDivider : AppColors.lightDivider);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

        return SizedBox(
          width: boxWidth,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: lineColor),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
