import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/attendance_provider.dart';

class ParticipantsScreen extends StatefulWidget {
  final String? initialEventId;

  const ParticipantsScreen({super.key, this.initialEventId});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEventId;
  String _searchQuery = '';
  String _selectedStatusFilter = 'all'; // 'all', 'attended', 'pending', 'cancelled'

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id).then((_) {
          if (!mounted) return;
          final events = context.read<EventProvider>().organizerEvents;
          final effectiveId = _getEffectiveEventId(events);
          if (effectiveId != null) {
            setState(() => _selectedEventId = effectiveId);
            context.read<AttendanceProvider>().loadEventParticipants(effectiveId);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getEffectiveEventId(List<EventModel> events) {
    if (_selectedEventId != null && events.any((e) => e.id == _selectedEventId)) {
      return _selectedEventId;
    }
    if (events.isNotEmpty) {
      return events.first.id;
    }
    return null;
  }

  void _onEventSelected(String? eventId) {
    if (eventId == null) return;
    setState(() {
      _selectedEventId = eventId;
    });
    context.read<AttendanceProvider>().loadEventParticipants(eventId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    final eventProvider = context.watch<EventProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final events = eventProvider.organizerEvents;
    final effectiveSelectedId = _getEffectiveEventId(events);

    var participants = attendanceProvider.eventParticipants;

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      participants = participants.where((p) =>
          (p.userName ?? '').toLowerCase().contains(q) ||
          (p.userEmail ?? '').toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.qrCode.toLowerCase().contains(q)).toList();
    }

    // Filter by status chip
    if (_selectedStatusFilter == 'attended') {
      participants = participants.where((p) => attendanceProvider.isAttendeeCheckedIn(p.id)).toList();
    } else if (_selectedStatusFilter == 'pending') {
      participants = participants.where((p) => p.isRegistered && !attendanceProvider.isAttendeeCheckedIn(p.id)).toList();
    } else if (_selectedStatusFilter == 'cancelled') {
      participants = participants.where((p) => p.isCancelled).toList();
    }

    final totalCount = attendanceProvider.eventParticipants.length;
    final attendedCount = attendanceProvider.totalCheckedIn;
    final pendingCount = attendanceProvider.eventParticipants.where((p) => p.isRegistered && !attendanceProvider.isAttendeeCheckedIn(p.id)).length;
    final cancelledCount = attendanceProvider.eventParticipants.where((p) => p.isCancelled).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Participant Roster',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (effectiveSelectedId != null) {
            await attendanceProvider.loadEventParticipants(effectiveSelectedId);
          }
        },
        child: Column(
          children: [
            // Event Dropdown Filter
            if (events.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppColors.darkSurface : const Color(0xFFF3EFE6),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: effectiveSelectedId,
                    items: events.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: _onEventSelected,
                  ),
                ),
              ),

            // Attendance KPI Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered: ${attendanceProvider.totalRegistered}',
                        style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Checked In: ${attendanceProvider.totalCheckedIn}',
                        style: AppTypography.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: indigoAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${attendanceProvider.attendanceRate.toStringAsFixed(1)}% Turnout',
                      style: AppTypography.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: indigoAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All ($totalCount)', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('attended', 'Attended ($attendedCount)', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Awaiting ($pendingCount)', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('cancelled', 'Cancelled ($cancelledCount)', isDark),
                ],
              ),
            ),

            // Search Field with clear icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search attendees by name, email, or pass ID...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),

            // Participants List
            Expanded(
              child: attendanceProvider.isLoading
                  ? const LoadingView(message: 'Loading participant roster...')
                  : participants.isEmpty
                      ? EmptyStateView(
                          icon: Icons.people_outline_rounded,
                          title: _searchQuery.isNotEmpty
                              ? 'No Matching Attendees'
                              : 'No Participants in this Category',
                          message: _searchQuery.isNotEmpty
                              ? 'Try adjusting your search query or status filter.'
                              : 'Registered participants will appear here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: participants.length,
                          itemBuilder: (context, idx) {
                            final p = participants[idx];
                            final isCheckedIn = attendanceProvider.isAttendeeCheckedIn(p.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isCheckedIn
                                          ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                          : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEDEAE1)),
                                      child: Text(
                                        (p.userName ?? 'A')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: isCheckedIn ? Colors.white : primaryTextColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.userName ?? 'Attendee',
                                            style: AppTypography.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: primaryTextColor,
                                            ),
                                          ),
                                          Text(
                                            p.userEmail ?? '',
                                            style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Registered: ${DateFormatter.formatRelative(p.registeredAt)}',
                                            style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      status: isCheckedIn ? 'attended' : p.status,
                                      fontSize: 10,
                                      iconSize: 11,
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
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _selectedStatusFilter == filterKey;
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.manrope(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ),
      selected: isSelected,
      selectedColor: indigoAccent,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEDEAE1),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() => _selectedStatusFilter = filterKey);
      },
    );
  }
}
