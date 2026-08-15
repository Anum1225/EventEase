import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';

class EventApprovalsScreen extends StatefulWidget {
  const EventApprovalsScreen({super.key});

  @override
  State<EventApprovalsScreen> createState() => _EventApprovalsScreenState();
}

class _EventApprovalsScreenState extends State<EventApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadPendingApprovals();
    });
  }

  void _showRejectDialog(BuildContext context, EventModel event) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text(
          'Reject Event Submission',
          style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please specify the justification for rejecting "${event.title}". The organizer will receive this feedback.',
                style: AppTypography.manrope(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Missing safety guidelines, duplicate event, incomplete venue info...',
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'A rejection reason is mandatory'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightError),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await context.read<EventProvider>().rejectEvent(
                event.id,
                reasonController.text.trim(),
                event.organizerId,
                event.title,
              );
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event rejected and feedback sent to organizer.')),
                );
              }
            },
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _approveEvent(EventModel event) async {
    final success = await context.read<EventProvider>().approveEvent(
      event.id,
      event.organizerId,
      event.title,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event "${event.title}" approved and published publicly!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final eventProvider = context.watch<EventProvider>();
    final pendingEvents = eventProvider.pendingApprovalEvents;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event Approval Queue',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => eventProvider.loadPendingApprovals(),
        child: eventProvider.isLoading
            ? const LoadingView(message: 'Loading pending submissions...')
            : pendingEvents.isEmpty
                ? const EmptyStateView(
                    icon: Icons.task_alt_rounded,
                    title: 'Queue is Empty',
                    message: 'All submitted events have been reviewed. No pending approvals at this time.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: pendingEvents.length,
                    itemBuilder: (context, idx) {
                      final event = pendingEvents[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: AppCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CategoryChip(category: event.category),
                                  Text(
                                    DateFormatter.formatRelative(event.createdAt),
                                    style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.title,
                                style: AppTypography.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                event.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.manrope(fontSize: 13.5, height: 1.4, color: primaryTextColor),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF3EFE6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Organizer: ${event.organizerName ?? "Host"} (${event.organizerEmail ?? "N/A"})',
                                      style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Schedule: ${DateFormatter.formatShortDate(event.date)} • ${event.startTime} - ${event.endTime}',
                                      style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Venue: ${event.location}',
                                      style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Max Capacity: ${event.maxParticipants} attendees',
                                      style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      text: 'Reject',
                                      variant: AppButtonVariant.destructive,
                                      icon: Icons.close_rounded,
                                      height: 42,
                                      onPressed: () => _showRejectDialog(context, event),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton(
                                      text: 'Approve & Publish',
                                      variant: AppButtonVariant.primary,
                                      icon: Icons.check_rounded,
                                      height: 42,
                                      onPressed: () => _approveEvent(event),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
