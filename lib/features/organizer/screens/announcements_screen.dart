import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/notification_provider.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String? initialEventId;

  const AnnouncementsScreen({super.key, this.initialEventId});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedEventId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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

  void _send() async {
    if (!_formKey.currentState!.validate()) return;

    final events = context.read<EventProvider>().organizerEvents;
    final effectiveId = _getEffectiveEventId(events);

    if (effectiveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target event')),
      );
      return;
    }

    setState(() => _isSending = true);

    final notifProvider = context.read<NotificationProvider>();
    final success = await notifProvider.sendAnnouncement(
      eventId: effectiveId,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
    );

    setState(() => _isSending = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement successfully broadcasted to all registered attendees!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final events = context.watch<EventProvider>().organizerEvents;
    final effectiveSelectedId = _getEffectiveEventId(events);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Broadcast Announcement',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      size: 24,
                      color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Broadcast important reminders, schedule changes, or parking instructions directly to your attendees.',
                        style: AppTypography.manrope(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Event *',
                      style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: effectiveSelectedId,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        hintText: 'Select an event',
                      ),
                      items: events.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            '${e.title} (${e.registeredCount} attendees)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select a target event' : null,
                      onChanged: (val) => setState(() => _selectedEventId = val),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Announcement Subject / Title *',
                      hint: 'e.g. Venue Entry Instructions & Parking Guide',
                      controller: _titleController,
                      validator: (v) => Validators.required(v, 'Title'),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Message Body *',
                      hint: 'Write your message to all registered participants...',
                      controller: _messageController,
                      maxLines: 5,
                      validator: (v) => Validators.required(v, 'Message body'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: 'Send Broadcast',
                variant: AppButtonVariant.organizer,
                icon: Icons.send_rounded,
                onPressed: _send,
                isLoading: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
