import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_model.dart';
import '../../../repositories/event_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feedback_provider.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final String eventId;

  const SubmitFeedbackScreen({super.key, required this.eventId});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final _eventRepo = EventRepository();
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  EventModel? _event;
  bool _isLoading = true;
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadEventAndStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadEventAndStatus() async {
    final user = context.read<AuthProvider>().currentUser;
    final fbProvider = context.read<FeedbackProvider>();

    try {
      final ev = await _eventRepo.getEventById(widget.eventId);
      if (user != null) {
        await fbProvider.checkUserFeedbackStatus(user.id, widget.eventId);
      }

      if (mounted) {
        setState(() {
          _event = ev;
          _alreadySubmitted = fbProvider.hasSubmittedForEvent(widget.eventId);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _event == null) return;

    if (!_event!.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback can only be submitted after the event has completed.'),
          backgroundColor: AppColors.lightError,
        ),
      );
      return;
    }

    final fbProvider = context.read<FeedbackProvider>();
    final success = await fbProvider.submitFeedback(
      eventId: _event!.id,
      userId: user.id,
      userName: user.name,
      rating: _selectedRating,
      comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
    );

    if (success && mounted) {
      setState(() {
        _alreadySubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! Your feedback has been recorded.')),
      );
    } else if (fbProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fbProvider.errorMessage!), backgroundColor: AppColors.lightError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fbProvider = context.watch<FeedbackProvider>();

    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading feedback form...'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Feedback'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _alreadySubmitted
                ? AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 54, color: AppColors.lightSuccess),
                        const SizedBox(height: 16),
                        Text(
                          'Feedback Submitted',
                          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your feedback for "${_event?.title ?? "this event"}" has been securely recorded.',
                          textAlign: TextAlign.center,
                          style: AppTypography.manrope(fontSize: 14, color: secondaryTextColor),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Back to My Events',
                          onPressed: () => context.go('/attendee/my-events'),
                        ),
                      ],
                    ),
                  )
                : (_event != null && !_event!.isCompleted)
                    ? AppCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_clock_rounded, size: 54, color: Colors.amber),
                            const SizedBox(height: 16),
                            Text(
                              'Feedback Locked',
                              style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Feedback for "${_event?.title ?? "this event"}" is unavailable until the event has concluded.',
                              textAlign: TextAlign.center,
                              style: AppTypography.manrope(fontSize: 14, color: secondaryTextColor),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Back to My Events',
                              onPressed: () => context.go('/attendee/my-events'),
                            ),
                          ],
                        ),
                      )
                    : AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'How was your experience?',
                              textAlign: TextAlign.center,
                              style: AppTypography.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _event?.title ?? 'Event Review',
                              textAlign: TextAlign.center,
                              style: AppTypography.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Star Rating Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final ratingValue = index + 1;
                                final isSelected = ratingValue <= _selectedRating;
                                return IconButton(
                                  icon: Icon(
                                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 38,
                                    color: isSelected ? Colors.amber : secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedRating = ratingValue;
                                    });
                                  },
                                );
                              }),
                            ),
                            const SizedBox(height: 20),

                            AppTextField(
                              label: 'Comments & Suggestions (Optional)',
                              hint: 'Share what you loved or how the organizers could improve...',
                              controller: _commentController,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 24),

                            AppButton(
                              text: 'Submit Feedback',
                              onPressed: _submit,
                              isLoading: fbProvider.isSubmitting,
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
