import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_model.dart';
import '../../../models/contact_message_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/feedback_provider.dart';
import '../../../providers/contact_provider.dart';
import '../../../services/two_factor_email_service.dart';
import '../../../services/local_data_store.dart';
import '../../../repositories/notification_repository.dart';

class OrganizerFeedbackScreen extends StatefulWidget {
  final String? initialEventId;

  const OrganizerFeedbackScreen({super.key, this.initialEventId});

  @override
  State<OrganizerFeedbackScreen> createState() => _OrganizerFeedbackScreenState();
}

class _OrganizerFeedbackScreenState extends State<OrganizerFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedEventId = widget.initialEventId ?? 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadAllMessages();
      final effectiveId = _selectedEventId ?? 'all';
      context.read<FeedbackProvider>().subscribeToEventFeedback(effectiveId);

      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id, user.email).then((_) {
          if (!mounted) return;
          final updatedEffectiveId = _selectedEventId ?? 'all';
          setState(() => _selectedEventId = updatedEffectiveId);
          final eventIds = context.read<EventProvider>().organizerEvents.map((e) => e.id).toList();
          context.read<FeedbackProvider>().subscribeToEventFeedback(updatedEffectiveId, eventIds);
          context.read<ContactProvider>().loadAllMessages();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getEffectiveEventId(List<EventModel> events) {
    if (_selectedEventId == 'all') return 'all';
    if (_selectedEventId != null && events.any((e) => e.id == _selectedEventId)) {
      return _selectedEventId!;
    }
    return 'all';
  }

  void _onEventSelected(String? eventId) {
    if (eventId == null) return;
    setState(() => _selectedEventId = eventId);
    final eventIds = context.read<EventProvider>().organizerEvents.map((e) => e.id).toList();
    context.read<FeedbackProvider>().subscribeToEventFeedback(eventId, eventIds);
  }

  void _showReplyDialog(BuildContext context, ContactMessageModel msg) {
    final replyController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        backgroundColor: isDark ? const Color(0xFF1E2232) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.reply_rounded, color: indigoAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reply to ${msg.name}',
                        style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Attendee Message:',
                  style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF5F2EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg.message,
                    style: AppTypography.manrope(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replyController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Type your reply message...',
                    hintStyle: AppTypography.manrope(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkTextSecondary : const Color(0xFF4F46E5),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final replyText = replyController.text.trim();
                        if (replyText.isEmpty) return;
                        Navigator.pop(ctx);

                        final currentOrganizer = context.read<AuthProvider>().currentUser;
                        final organizerName = currentOrganizer?.name ?? 'Event Organizer';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dispatching response to ${msg.email}...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        // 1. Dispatch real email to the user's email address
                        await TwoFactorEmailService.sendOrganizerReplyEmail(
                          toEmail: msg.email,
                          attendeeName: msg.name,
                          organizerName: organizerName,
                          subject: msg.subject,
                          originalMessage: msg.message,
                          replyMessage: replyText,
                        );

                        // 2. Dispatch real in-app notification to attendee's notification tab
                        String targetUserId = (msg.userId != null && msg.userId!.isNotEmpty && msg.userId != 'guest')
                            ? msg.userId!
                            : msg.email;

                        final matchedUser = LocalDataStore().getUserByEmail(msg.email);
                        if (matchedUser != null) {
                          targetUserId = matchedUser.id;
                        }

                        await NotificationRepository().sendNotification(
                          userId: targetUserId,
                          title: 'Organizer Response: ${msg.subject}',
                          message: '$organizerName replied: "$replyText"',
                          type: 'inquiry_response',
                        );

                        if (targetUserId != msg.email) {
                          await NotificationRepository().sendNotification(
                            userId: msg.email,
                            title: 'Organizer Response: ${msg.subject}',
                            message: '$organizerName replied: "$replyText"',
                            type: 'inquiry_response',
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Response sent to ${msg.name} (${msg.email}) and posted to their in-app notifications!'),
                              backgroundColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                            ),
                          );
                        }
                      },
                      child: const Text('Send Response', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    final events = context.watch<EventProvider>().organizerEvents;
    final feedbackProvider = context.watch<FeedbackProvider>();
    final contactProvider = context.watch<ContactProvider>();
    final effectiveSelectedId = _getEffectiveEventId(events);

    final reviews = feedbackProvider.getFeedbackForEvent(effectiveSelectedId);
    final avg = feedbackProvider.getAverageRating(effectiveSelectedId);
    final messages = contactProvider.messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews & Attendee Inquiries',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : indigoAccent,
          unselectedLabelColor: secondaryTextColor,
          indicatorColor: indigoAccent,
          tabs: [
            Tab(
              icon: const Icon(Icons.star_rounded, size: 18),
              text: 'Reviews (${reviews.length})',
            ),
            Tab(
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              text: 'Inquiries & Messages (${messages.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: REVIEWS & RATINGS
          RefreshIndicator(
            onRefresh: () async {
              final eventIds = events.map((e) => e.id).toList();
              await feedbackProvider.loadEventFeedback(effectiveSelectedId, eventIds);
            },
            child: Column(
              children: [
                // Event Dropdown Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF3EFE6),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: effectiveSelectedId,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.stars_rounded, size: 18, color: indigoAccent),
                              const SizedBox(width: 8),
                              Text(
                                'All Hosted Events (${events.length} Events)',
                                style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        ...events.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          );
                        }),
                      ],
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
                          Icon(
                            Icons.star_rounded,
                            size: 28,
                            color: reviews.isNotEmpty ? Colors.amber : (isDark ? Colors.white24 : Colors.black26),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reviews.isNotEmpty ? avg.toStringAsFixed(1) : '0.0',
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
                          color: (reviews.isEmpty
                                  ? (isDark ? Colors.white12 : Colors.black12)
                                  : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reviews.isEmpty
                              ? 'No Reviews'
                              : avg >= 4.5
                                  ? 'Top Rated'
                                  : avg >= 3.5
                                      ? 'Good'
                                      : 'Needs Attention',
                          style: AppTypography.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: reviews.isEmpty
                                ? secondaryTextColor
                                : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Reviews List
                Expanded(
                  child: feedbackProvider.isLoading
                      ? const LoadingView(message: 'Loading reviews...')
                      : reviews.isEmpty
                          ? const EmptyStateView(
                              icon: Icons.rate_review_outlined,
                              title: 'No Reviews Yet',
                              message: 'Attendees can leave reviews and star ratings once events conclude.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: reviews.length,
                              itemBuilder: (context, idx) {
                                final r = reviews[idx];
                                final name = r.userName ?? 'Attendee';
                                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: isDark ? AppColors.darkOrganizerAccent : const Color(0xFFE8E5DD),
                                                    child: Text(
                                                      initial,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: AppTypography.manrope(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: primaryTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormatter.formatRelative(r.submittedAt),
                                              style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: List.generate(5, (starIdx) {
                                            return Icon(
                                              starIdx < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                              size: 16,
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                        if (r.comment != null && r.comment!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            r.comment!,
                                            style: AppTypography.manrope(fontSize: 13, height: 1.4),
                                          ),
                                        ],
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

          // TAB 2: INQUIRIES & ATTENDEE COMMENTS
          RefreshIndicator(
            onRefresh: () async {
              await contactProvider.loadAllMessages();
            },
            child: contactProvider.messages.isEmpty
                ? const EmptyStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No Inquiries or Messages',
                    message: 'Messages, comments, and questions submitted by attendees will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: contactProvider.messages.length,
                    itemBuilder: (context, idx) {
                      final msg = contactProvider.messages[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent).withValues(alpha: 0.2),
                                    child: Icon(Icons.mail_outline_rounded, size: 16, color: indigoAccent),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.name,
                                          style: AppTypography.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        Text(
                                          msg.email,
                                          style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatRelative(msg.submittedAt),
                                    style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : const Color(0xFFF7F5EE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subject: ${msg.subject}',
                                      style: AppTypography.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg.message,
                                      style: AppTypography.manrope(fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showReplyDialog(context, msg),
                                    icon: const Icon(Icons.reply_rounded, size: 14),
                                    label: Text(
                                      'Reply to Attendee',
                                      style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }
}
