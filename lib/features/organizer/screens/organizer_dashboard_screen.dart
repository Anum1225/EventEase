import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/animated_charts.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/theme_provider.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id);
      }
    });
  }

  void _showCancelEventDialog(BuildContext context, EventModel event) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text(
          'Cancel Event?',
          style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel "${event.title}"? All registered participants will receive an immediate cancellation alert.',
                style: AppTypography.manrope(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Cancellation Reason',
                  hintText: 'e.g. Inclement weather, venue conflict...',
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please specify a reason for cancellation'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Event'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightError),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = context.read<AuthProvider>().currentUser;
              final success = await context.read<EventProvider>().cancelEvent(
                eventId: event.id,
                reason: reasonController.text.trim(),
                eventTitle: event.title,
                organizerId: auth?.id ?? '',
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Event cancelled and attendees notified.' : 'Failed to cancel event'),
                    backgroundColor: success ? AppColors.lightSuccess : AppColors.lightError,
                  ),
                );
              }
            },
            child: const Text('Confirm Cancellation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final user = authProvider.currentUser;
    final events = eventProvider.organizerEvents;

    final totalRegistrations = events.fold<int>(0, (sum, ev) => sum + ev.registeredCount);
    final approvedEventsCount = events.where((e) => e.isApproved).length;
    final pendingCount = events.where((e) => e.isPending).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: indigoAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.corporate_fare_rounded, size: 20, color: indigoAccent),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Organizer Portal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    user?.name ?? 'Host',
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
                message: 'Are you sure you want to sign out of EventEase?',
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
          if (user != null) {
            await eventProvider.loadOrganizerEvents(user.id);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview & Performance',
                style: AppTypography.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              // KPI Metrics Grid with Animated Counters
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Live Events',
                      approvedEventsCount,
                      Icons.event_available_rounded,
                      isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Registrations',
                      totalRegistrations,
                      Icons.group_rounded,
                      isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Pending Review',
                      pendingCount,
                      Icons.pending_actions_rounded,
                      isDark ? AppColors.darkWarning : AppColors.lightWarning,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Animated Bar Chart of Event Demand
              if (events.isNotEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendee Registrations Per Event',
                        style: AppTypography.manrope(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ModernAnimatedBarChart(
                        data: events.map((ev) {
                          return BarChartDataPoint(
                            label: ev.title.length > 8 ? '${ev.title.substring(0, 7)}..' : ev.title,
                            value: ev.registeredCount.toDouble(),
                            color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                          );
                        }).toList(),
                        height: 140,
                        yAxisSuffix: ' tix',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Create Event Callout Action
              AppButton(
                text: 'Create New Event',
                icon: Icons.add_rounded,
                variant: AppButtonVariant.organizer,
                onPressed: () => context.push('/organizer/create-event'),
              ),
              const SizedBox(height: 28),

              // Hosted Events Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Created Events (${events.length})',
                    style: AppTypography.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (eventProvider.isLoading && events.isEmpty)
                const EventListSkeleton(itemCount: 2)
              else if (events.isEmpty)
                EmptyStateView(
                  icon: Icons.event_note_rounded,
                  title: 'No Events Hosted Yet',
                  message: 'Start by creating your first event to welcome attendees.',
                  actionLabel: 'Create Event Now',
                  onAction: () => context.push('/organizer/create-event'),
                )
              else
                ...events.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppNetworkImage(
                                imageUrl: event.imageUrl,
                                width: 76,
                                height: 76,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        StatusBadge(status: event.status),
                                        const Spacer(),
                                        CategoryChip(category: event.category, fontSize: 10, iconSize: 11),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormatter.formatDate(event.date),
                                      style: AppTypography.manrope(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Capacity Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Registrations: ${event.registeredCount} / ${event.maxParticipants}',
                                style: AppTypography.manrope(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                              Text(
                                '${event.remainingSeats} seats left',
                                style: AppTypography.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: event.isFull ? AppColors.lightError : AppColors.lightSuccess,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.maxParticipants > 0
                                  ? (event.registeredCount / event.maxParticipants).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE5E2D6),
                              valueColor: AlwaysStoppedAnimation<Color>(indigoAccent),
                            ),
                          ),

                          if (event.rejectionReason != null && event.isRejected) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Rejection note: ${event.rejectionReason}',
                                style: AppTypography.manrope(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkError : AppColors.lightError,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Action Buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                label: const Text('Scan QR'),
                                onPressed: () => context.push('/organizer/scanner?eventId=${event.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: indigoAccent,
                                  side: BorderSide(color: indigoAccent.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.people_outline_rounded, size: 16),
                                label: const Text('Roster'),
                                onPressed: () => context.push('/organizer/participants?eventId=${event.id}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.campaign_outlined, size: 16),
                                label: const Text('Announce'),
                                onPressed: () => context.push('/organizer/announcements?eventId=${event.id}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library_outlined, size: 16),
                                label: const Text('Gallery'),
                                onPressed: () => context.push('/organizer/gallery-upload?eventId=${event.id}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.star_outline_rounded, size: 16),
                                label: const Text('Feedback'),
                                onPressed: () => context.push('/organizer/feedback?eventId=${event.id}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              if (!event.isCancelled && !event.isCompleted) ...[
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                  onPressed: () => context.push('/organizer/edit-event/${event.id}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: const Text('Cancel'),
                                  onPressed: () => _showCancelEventDialog(context, event),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? AppColors.darkError : AppColors.lightError,
                                    side: BorderSide(color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, num value, IconData icon, Color color, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          AnimatedMetricCounter(
            value: value,
            textStyle: AppTypography.manrope(
              fontSize: 20,
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
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
