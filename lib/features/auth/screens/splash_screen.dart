import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward();

    // Initialize application and navigate to appropriate shell after splash
    _timer = Timer(const Duration(milliseconds: 2400), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) {
        context.go('/attendee');
        return;
      }

      final role = authProvider.role;
      if (role == AppConstants.roleAdmin) {
        context.go('/admin');
      } else if (role == AppConstants.roleOrganizer) {
        context.go('/organizer');
      } else if (role == AppConstants.roleOrganizerPending) {
        context.go('/organizer-pending');
      } else {
        context.go('/attendee');
      }
    } catch (_) {
      context.go('/attendee');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFF0F1015),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Multi-layer Ambient Radial Glows
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.lightAccent.withValues(alpha: 0.28),
                            AppColors.darkOrganizerAccent.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Centered Splash Hero Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing App Icon / Logo
                    Container(
                      width: 116,
                      height: 116,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightAccent.withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/app_logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.lightAccent,
                            child: const Icon(
                              Icons.confirmation_number_rounded,
                              size: 54,
                              color: AppColors.lightOnAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App Title with Fraunces Signature Italic
                    Text(
                      AppConstants.appName,
                      style: AppTypography.frauncesSignature(
                        fontSize: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle / Tagline Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Text(
                        AppConstants.appTagline,
                        style: AppTypography.manrope(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Subtle Pulse Loading Indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Version Branding
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Text(
              'Institutional Edition • v1.0.0',
              textAlign: TextAlign.center,
              style: AppTypography.manrope(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
