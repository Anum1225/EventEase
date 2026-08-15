import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../providers/auth_provider.dart';

class OrganizerPendingScreen extends StatelessWidget {
  const OrganizerPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Under Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Check Status',
            onPressed: () async {
              await authProvider.refreshUser();
              if (context.mounted && authProvider.role == 'organizer') {
                context.go('/organizer');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkWarning : AppColors.lightWarning)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 52,
                      color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Organizer Application Pending',
                    textAlign: TextAlign.center,
                    style: AppTypography.frauncesSignature(
                      fontSize: 24,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Thank you for applying to organize events with EventEase, ${user?.name ?? "Partner"}.',
                    textAlign: TextAlign.center,
                    style: AppTypography.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Per institutional guidelines (SRS 1.6.1 & 1.6.2), new organizer accounts must be reviewed and approved by a system administrator prior to granting publishing permissions.',
                    textAlign: TextAlign.center,
                    style: AppTypography.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF3EFE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 20,
                          color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Status: Pending Admin Review\nAccount: ${user?.email ?? ""}',
                            style: AppTypography.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'Refresh Status',
                    onPressed: () async {
                      await authProvider.refreshUser();
                      if (context.mounted && authProvider.role == 'organizer') {
                        context.go('/organizer');
                      }
                    },
                    icon: Icons.refresh_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Explore Events as Attendee',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => context.go('/attendee'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
