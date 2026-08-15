import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/event_provider.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadAllAdminEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    context.read<EventProvider>().loadAllAdminEvents(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      query: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final eventProvider = context.watch<EventProvider>();
    final events = eventProvider.allAdminEvents;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'System Event Directory',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _onFilterChanged(),
              decoration: const InputDecoration(
                hintText: 'Search by title, location, category...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Status Filter Tabs
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusFilterChip('All Statuses', 'all', isDark, primaryTextColor),
                _buildStatusFilterChip('Approved', AppConstants.eventStatusApproved, isDark, primaryTextColor),
                _buildStatusFilterChip('Pending', AppConstants.eventStatusPendingApproval, isDark, primaryTextColor),
                _buildStatusFilterChip('Completed', AppConstants.eventStatusCompleted, isDark, primaryTextColor),
                _buildStatusFilterChip('Cancelled', AppConstants.eventStatusCancelled, isDark, primaryTextColor),
                _buildStatusFilterChip('Rejected', AppConstants.eventStatusRejected, isDark, primaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Events List
          Expanded(
            child: eventProvider.isLoading
                ? const LoadingView(message: 'Loading system events...')
                : events.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.event_busy_rounded,
                        title: 'No Events Found',
                        message: 'No events match the selected status or query.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, idx) {
                          final event = events[idx];

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
                                      CategoryChip(category: event.category, fontSize: 10, iconSize: 12),
                                      StatusBadge(status: event.status, fontSize: 10, iconSize: 12),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    event.title,
                                    style: AppTypography.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Host: ${event.organizerName ?? "Organizer"} (${event.organizerEmail ?? "N/A"})',
                                    style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                  ),
                                  Text(
                                    '${DateFormatter.formatShortDate(event.date)} • ${event.registeredCount}/${event.maxParticipants} Registered',
                                    style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                  ),
                                  const Divider(height: 18),

                                  // Action buttons (View Details, Edit, Delete)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.visibility_outlined, size: 15),
                                        label: const Text('View', style: TextStyle(fontSize: 12)),
                                        onPressed: () => context.push('/event-details/${event.id}'),
                                      ),
                                      const SizedBox(width: 6),
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined, size: 15),
                                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                        onPressed: () => context.push('/organizer/edit-event/${event.id}'),
                                      ),
                                      const SizedBox(width: 6),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(foregroundColor: AppColors.lightError),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                                        label: const Text('Delete', style: TextStyle(fontSize: 12)),
                                        onPressed: () async {
                                          final confirm = await ConfirmationDialog.show(
                                            context,
                                            title: 'Delete Event?',
                                            message: 'Are you sure you want to permanently delete "${event.title}" from the database?',
                                            confirmLabel: 'Delete',
                                            isDestructive: true,
                                          );
                                          if (confirm && context.mounted) {
                                            final success = await eventProvider.deleteEvent(event.id);
                                            if (success && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Event "${event.title}" deleted.')),
                                              );
                                            }
                                          }
                                        },
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
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String statusVal, bool isDark, Color primaryColor) {
    final isSelected = _selectedStatus == statusVal;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedStatus = statusVal);
          _onFilterChanged();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        selectedColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        labelStyle: TextStyle(
          color: isSelected
              ? (isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent)
              : primaryColor,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
