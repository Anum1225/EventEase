import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About EventEase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Brand Presentation
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.confirmation_num_rounded,
                  size: 48,
                  color: isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: AppTypography.frauncesSignature(
                fontSize: 28,
                color: primaryTextColor,
              ),
            ),
            Text(
              AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: AppTypography.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Project Mission Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: AppTypography.manrope(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'EventEase was engineered to eliminate friction from live event discovery, registration, and attendance verification. Built upon an approved institutional Software Requirements Specification (SRS), the platform bridges Attendees, Organizers, and Administrators in a unified, cross-platform ecosystem.',
                    style: AppTypography.manrope(fontSize: 14, height: 1.5, color: primaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Key Architectural Highlights
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Core System Pillars',
                    style: AppTypography.manrope(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.security_rounded,
                    'Role-Based Multi-Tier Security',
                    'Enforced at the Firestore and Storage database security rules level, preventing unauthorized access.',
                    isDark,
                  ),
                  const Divider(height: 20),
                  _buildFeatureRow(
                    Icons.bolt_rounded,
                    'Atomic 7-Step Transactions',
                    'Prevents race conditions, capacity over-allocation, and duplicate registrations concurrently.',
                    isDark,
                  ),
                  const Divider(height: 20),
                  _buildFeatureRow(
                    Icons.qr_code_scanner_rounded,
                    'Verified QR Attendance',
                    'Single-scan ticket verification with instant duplicate check-in rejection.',
                    isDark,
                  ),
                  const Divider(height: 20),
                  _buildFeatureRow(
                    Icons.palette_rounded,
                    'Award-Winning Design System',
                    'Signal Lime (#C6F135), warm-neutral palettes, dual-mode WCAG AA contrast, and ticket-stub visual geometry.',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Project Team & Technical Specifications
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Specifications',
                    style: AppTypography.manrope(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text('• Framework: Flutter Multi-Platform (Android / iOS / Web)', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                  const SizedBox(height: 4),
                  Text('• State Management: Provider Architecture', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                  const SizedBox(height: 4),
                  Text('• Backend: Firebase Auth, Cloud Firestore, Cloud Storage, FCM', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                  const SizedBox(height: 4),
                  Text('• Version: 1.0.0 (Release Edition)', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.manrope(fontSize: 12.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
