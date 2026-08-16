import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';

/// The Signature Moment: Custom-crafted VIP Ticket-Stub QR Pass Card
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
      duration: const Duration(milliseconds: 400),
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

  void _copyPassId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.registrationId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Pass ID copied to clipboard: ${widget.registrationId.toUpperCase()}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              // Radial Glow Source behind ticket
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
                clipper: TicketStubClipper(notchRadius: 14, notchPositionFraction: 0.52),
                color: cardBg,
                elevation: isDark ? 0 : 10,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                child: SizedBox(
                  width: math.min(MediaQuery.of(context).size.width - 40, 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Event Banner & Title Section
                      _buildTopSection(isDark, primaryTextColor, secondaryTextColor),

                      // Perforated Divider Line with Notch Alignment
                      const PerforatedDivider(),

                      // Bottom Custom QR Code Container Section
                      _buildBottomSection(context, isDark, primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
              ),

              // "CHECKED IN" Stamp Overlay
              if (widget.hasAttended)
                Positioned(
                  bottom: 120,
                  child: Transform.rotate(
                    angle: -0.22, // ~ -12.5 degrees rotation
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            .withValues(alpha: 0.16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CHECKED IN',
                            style: AppTypography.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                            ),
                          ),
                          if (widget.checkedInAt != null)
                            Text(
                              DateFormatter.formatDateTime(widget.checkedInAt),
                              style: AppTypography.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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
      height: 210,
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
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),

          // Content Details
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (widget.category != null)
                      Container(
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
                    const Spacer(),
                    // Live Pass Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (widget.hasAttended ? const Color(0xFF10B981) : const Color(0xFFEAB308))
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: widget.hasAttended ? const Color(0xFF10B981) : const Color(0xFFEAB308),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.hasAttended ? const Color(0xFF10B981) : const Color(0xFFEAB308),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.hasAttended ? 'ATTENDED' : 'VALID PASS',
                            style: AppTypography.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Signature Title: Fraunces Signature
                Text(
                  widget.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.frauncesSignature(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFFF3F1E9)),
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
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFF3F1E9)),
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
                if (widget.location != null && widget.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFDDD8CE)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFDDD8CE),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isDark, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom QR Code Viewport with 4-Corner Viewfinder Brackets
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2DDD3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom-Styled QR Matrix
                QrImageView(
                  data: widget.qrCodePayload,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Color(0xFF0F172A),
                  ),
                ),

                // Center Branded Shield Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_num_rounded,
                        size: 15,
                        color: Color(0xFFD4E034), // Signal Lime accent
                      ),
                    ),
                  ),
                ),

                // 4 Corner Viewfinder Brackets
                const Positioned(
                  top: 0,
                  left: 0,
                  child: _CornerBracket(isTop: true, isLeft: true),
                ),
                const Positioned(
                  top: 0,
                  right: 0,
                  child: _CornerBracket(isTop: true, isLeft: false),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  child: _CornerBracket(isTop: false, isLeft: true),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: _CornerBracket(isTop: false, isLeft: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Holographic Security Foil Simulation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                  Color(0xFFF1F5F9),
                  Color(0xFFE2E8F0),
                ],
              ),
              border: Border.all(color: const Color(0xFF94A3B8), width: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'SECURITY TOKEN VERIFIED • EVENTEASE PASS',
                    style: AppTypography.manrope(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

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

          InkWell(
            onTap: () => _copyPassId(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pass ID: ${widget.registrationId.toUpperCase()}',
                    style: AppTypography.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: secondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom corner bracket for high-tech QR viewfinder aesthetic
class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    const thickness = 2.5;
    const color = Color(0xFF334155);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BracketPainter(isTop: isTop, isLeft: isLeft, thickness: thickness, color: color),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final Color color;

  _BracketPainter({
    required this.isTop,
    required this.isLeft,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Clipper creating circular ticket notches on left and right edges
class TicketStubClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchPositionFraction;

  TicketStubClipper({
    this.notchRadius = 14.0,
    this.notchPositionFraction = 0.52,
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

