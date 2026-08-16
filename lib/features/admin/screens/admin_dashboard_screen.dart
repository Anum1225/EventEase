import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_charts.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/theme_provider.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().computeSystemStatistics();
      context.read<EventProvider>().loadPendingApprovals();
      context.read<AdminProvider>().loadPendingOrganizers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final adminProvider = context.watch<AdminProvider>();
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
    final stats = adminProvider.statistics;

    final pendingEventCount = eventProvider.pendingApprovalEvents.length;
    final pendingOrgCount = adminProvider.pendingOrganizers.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                size: 20,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Institutional Admin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Governance Console',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.manrope(fontSize: 11.5, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Attendee View',
            onPressed: () => context.go('/attendee'),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () async {
              final confirm = await ConfirmationDialog.show(
                context,
                title: 'Sign Out?',
                message: 'Are you sure you want to sign out of the Admin Console?',
                confirmLabel: 'Sign Out',
                isDestructive: true,
              );
              if (confirm && context.mounted) {
                await authProvider.logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await adminProvider.computeSystemStatistics();
          await eventProvider.loadPendingApprovals();
          await adminProvider.loadPendingOrganizers();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Action Callouts Banner (if any pending)
              if (pendingEventCount > 0 || pendingOrgCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.pending_actions_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Action Required: Pending Items',
                            style: AppTypography.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (pendingEventCount > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                icon: const Icon(Icons.event_note_rounded, size: 16),
                                label: Text(
                                  '$pendingEventCount Event${pendingEventCount > 1 ? "s" : ""}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () => context.go('/admin/approvals'),
                              ),
                            ),
                          if (pendingEventCount > 0 && pendingOrgCount > 0)
                            const SizedBox(width: 8),
                          if (pendingOrgCount > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                label: Text(
                                  '$pendingOrgCount Host App${pendingOrgCount > 1 ? "s" : ""}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () => context.go('/admin/users'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                'System Vital Signs',
                style: AppTypography.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              // KPI Metric Cards with Animated Counters
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Users',
                      stats?.totalUsers ?? 0,
                      Icons.people_alt_rounded,
                      isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Events',
                      stats?.totalEvents ?? 0,
                      Icons.event_seat_rounded,
                      isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Registrations',
                      stats?.totalRegistrations ?? 0,
                      Icons.confirmation_number_rounded,
                      isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Avg Feedback',
                      stats?.averageSystemRating ?? 0.0,
                      Icons.star_rounded,
                      Colors.amber,
                      isDark,
                      suffix: ' ★',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Analytics Card
              if (stats != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Institutional Breakdown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => context.go('/admin/reports'),
                            child: const Text('View All →', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: ModernAnimatedDonutChart(
                          size: 150,
                          strokeWidth: 14,
                          centerTitle: '${stats.totalApprovedEvents}',
                          centerSubtitle: 'Live Events',
                          segments: [
                            DonutSegment(
                              label: 'Approved',
                              value: stats.totalApprovedEvents.toDouble(),
                              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                            ),
                            DonutSegment(
                              label: 'Pending',
                              value: stats.totalPendingApprovals.toDouble(),
                              color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Quick Administration Modules
              Text(
                'Administrative Tools',
                style: AppTypography.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              _buildAdminActionTile(
                title: 'Event Approvals Queue',
                subtitle: '$pendingEventCount events waiting for institutional review',
                icon: Icons.fact_check_rounded,
                badgeCount: pendingEventCount,
                onTap: () => context.go('/admin/approvals'),
                color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildAdminActionTile(
                title: 'User Management & Roles',
                subtitle: 'Manage user profiles, organizer approval requests, and status',
                icon: Icons.manage_accounts_rounded,
                badgeCount: pendingOrgCount,
                onTap: () => context.go('/admin/users'),
                color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildAdminActionTile(
                title: 'Global Event Governance',
                subtitle: 'Inspect, edit, moderate, or cancel all platform events',
                icon: Icons.event_note_rounded,
                onTap: () => context.go('/admin/events'),
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildAdminActionTile(
                title: 'Gallery Media Moderation',
                subtitle: 'Review attendee and organizer photo memories',
                icon: Icons.photo_filter_rounded,
                onTap: () => context.push('/admin/gallery-moderation'),
                color: Colors.teal,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildAdminActionTile(
                title: 'Reports & Analytics',
                subtitle: 'View detailed attendance rates, event reach, and averages',
                icon: Icons.analytics_rounded,
                onTap: () => context.go('/admin/reports'),
                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                isDark: isDark,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, num value, IconData icon, Color color, bool isDark, {String suffix = ''}) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 10),
          AnimatedMetricCounter(
            value: value,
            suffix: suffix,
            textStyle: AppTypography.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    int badgeCount = 0,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.manrope(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badgeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.manrope(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}
