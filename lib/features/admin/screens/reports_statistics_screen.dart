import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_charts.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../providers/admin_provider.dart';

class ReportsStatisticsScreen extends StatefulWidget {
  const ReportsStatisticsScreen({super.key});

  @override
  State<ReportsStatisticsScreen> createState() => _ReportsStatisticsScreenState();
}

class _ReportsStatisticsScreenState extends State<ReportsStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().computeSystemStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.statistics;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Institutional Reports & Analytics',
          style: AppTypography.manrope(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: adminProvider.isLoading && stats == null
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  Row(
                    children: const [
                      Expanded(child: StatCardSkeleton()),
                      SizedBox(width: 12),
                      Expanded(child: StatCardSkeleton()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const EventCardSkeleton(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => adminProvider.computeSystemStatistics(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Summary',
                      style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: primaryTextColor),
                    ),
                    const SizedBox(height: 12),

                    // Primary KPI Cards with Animated Counters
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'User Base',
                            stats?.totalUsers ?? 0,
                            '${stats?.totalOrganizers ?? 0} Organizers • ${stats?.totalAttendees ?? 0} Attendees',
                            Icons.groups_rounded,
                            isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Event Pipeline',
                            stats?.totalEvents ?? 0,
                            '${stats?.totalApprovedEvents ?? 0} Approved • ${stats?.totalPendingApprovals ?? 0} Pending',
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
                          child: _buildSummaryCard(
                            'Engagement',
                            stats?.totalRegistrations ?? 0,
                            'Total tickets claimed system-wide',
                            Icons.confirmation_number_rounded,
                            isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Verified Check-Ins',
                            stats?.totalCheckIns ?? 0,
                            'Total scans logged by organizers',
                            Icons.qr_code_scanner_rounded,
                            Colors.purpleAccent,
                            isDark,
                          ),
                        ),
                      ],
                    const SizedBox(height: 12),

                    // Feedback & Satisfaction KPI
                    if (stats != null)
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 22, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  'Overall Feedback Score',
                                  style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                AnimatedMetricCounter(
                                  value: stats.averageSystemRating,
                                  isDecimal: true,
                                  textStyle: AppTypography.manrope(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ 5.0',
                                  style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: secondaryTextColor),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: List.generate(5, (i) {
                                    final filled = i < stats.averageSystemRating.round();
                                    return Icon(
                                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 20,
                                      color: filled ? Colors.amber : secondaryTextColor,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aggregated from all post-event attendee reviews across the platform',
                              style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),

                    // Animated Visual Analytics Section
                    if (stats != null) ...[
                      Text(
                        'System Breakdown & Ratio',
                        style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: primaryTextColor),
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ModernAnimatedDonutChart(
                              centerTitle: '${stats.totalUsers}',
                              centerSubtitle: 'Total Members',
                              segments: [
                                DonutSegment(
                                  label: 'Attendees',
                                  value: (stats.totalAttendees).toDouble(),
                                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                ),
                                DonutSegment(
                                  label: 'Organizers',
                                  value: (stats.totalOrganizers).toDouble(),
                                  color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Animated Bar Chart for Popular Events
                      if (stats.popularEvents.isNotEmpty) ...[
                        Text(
                          'Event Demand & Registrations',
                          style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: primaryTextColor),
                        ),
                        const SizedBox(height: 14),
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: ModernAnimatedBarChart(
                            data: stats.popularEvents.take(5).map((e) {
                              return BarChartDataPoint(
                                label: e.title.length > 9 ? '${e.title.substring(0, 8)}..' : e.title,
                                value: e.registeredCount.toDouble(),
                                color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                              );
                            }).toList(),
                            height: 180,
                            yAxisSuffix: ' reg',
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ],

                    // Most Popular Events (Leaderboard)
                    Text(
                      'Popular Events Leaderboard',
                      style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: primaryTextColor),
                    ),
                    const SizedBox(height: 12),

                    if (stats == null || stats.popularEvents.isEmpty)
                      Text('No event registrations recorded yet.', style: TextStyle(color: secondaryTextColor))
                    else
                      ...stats.popularEvents.map((ev) {
                        final fillPercent = ev.maxParticipants > 0
                            ? (ev.registeredCount / ev.maxParticipants).clamp(0.0, 1.0)
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ev.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CategoryChip(category: ev.category, fontSize: 10, iconSize: 11),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${ev.registeredCount} / ${ev.maxParticipants} Registered',
                                      style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
                                    ),
                                    Text(
                                      '${(fillPercent * 100).toStringAsFixed(0)}% Capacity',
                                      style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fillPercent,
                                    minHeight: 6,
                                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE5E2D6),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, num value, String subtitle, IconData icon, Color color, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          AnimatedMetricCounter(
            value: value,
            textStyle: AppTypography.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            title,
            style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.manrope(fontSize: 10.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}
