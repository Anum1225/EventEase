import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_model.dart';
import '../../../models/feedback_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/feedback_provider.dart';

class OrganizerFeedbackScreen extends StatefulWidget {
  final String? initialEventId;

  const OrganizerFeedbackScreen({super.key, this.initialEventId});

  @override
  State<OrganizerFeedbackScreen> createState() => _OrganizerFeedbackScreenState();
}

class _OrganizerFeedbackScreenState extends State<OrganizerFeedbackScreen> {
  String? _selectedEventId;

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
            context.read<FeedbackProvider>().loadEventFeedback(effectiveId);
          }
        });
      }
    });
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
    setState(() => _selectedEventId = eventId);
    context.read<FeedbackProvider>().loadEventFeedback(eventId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final events = context.watch<EventProvider>().organizerEvents;
    final feedbackProvider = context.watch<FeedbackProvider>();
    final effectiveSelectedId = _getEffectiveEventId(events);
    final reviews = effectiveSelectedId != null ? feedbackProvider.getFeedbackForEvent(effectiveSelectedId) : <FeedbackModel>[];
    final avg = effectiveSelectedId != null ? feedbackProvider.getAverageRating(effectiveSelectedId) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendee Reviews & Feedback',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (effectiveSelectedId != null) {
            await feedbackProvider.loadEventFeedback(effectiveSelectedId);
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

            // Rating Summary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 28, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        avg.toStringAsFixed(1),
                        style: AppTypography.manrope(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${reviews.length} Total Reviews)',
                        style: AppTypography.manrope(fontSize: 13, color: secondaryTextColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEDEAE1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Read-Only',
                      style: AppTypography.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryTextColor),
                    ),
                  ),
                ],
              ),
            ),

            // Feedback List
            Expanded(
              child: feedbackProvider.isLoading
                  ? const LoadingView(message: 'Loading reviews...')
                  : reviews.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.rate_review_outlined,
                          title: 'No Reviews Submitted Yet',
                          message: 'Attendee ratings and comments will appear here once submitted after event completion.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reviews.length,
                          itemBuilder: (context, idx) {
                            final fb = reviews[idx];
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
                                        Text(
                                          fb.userName ?? 'Attendee',
                                          style: AppTypography.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              i < fb.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                              size: 16,
                                              color: i < fb.rating ? Colors.amber : secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (fb.comment != null && fb.comment!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        fb.comment!,
                                        style: AppTypography.manrope(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          color: primaryTextColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormatter.formatRelative(fb.submittedAt),
                                      style: AppTypography.manrope(
                                        fontSize: 11,
                                        color: secondaryTextColor,
                                      ),
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
}
