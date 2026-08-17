import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/map_location_picker_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/event_model.dart';
import '../../../repositories/event_repository.dart';
import '../../../repositories/notification_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/registration_provider.dart';
import '../../../providers/feedback_provider.dart';
import '../../../providers/gallery_provider.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  EventModel? _event;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await context.read<RegistrationProvider>().loadUserData(user.id, user.email);
      }

      final eventRepo = EventRepository();
      final event = await eventRepo.getEventById(widget.eventId);
      if (event != null) {
        _event = event;
        if (mounted) {
          context.read<FeedbackProvider>().loadEventFeedback(event.id);
          context.read<GalleryProvider>().loadEventGallery(event.id);
        }
      } else {
        _errorMessage = 'Event not found.';
      }
    } catch (e) {
      _errorMessage = 'Failed to load event details: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onRegisterTapped() async {
    final authProvider = context.read<AuthProvider>();
    final regProvider = context.read<RegistrationProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      context.push('/login?reason=${Uri.encodeComponent('Event Registration')}');
      return;
    }

    if (_event == null) return;

    final reg = await regProvider.registerForEvent(
      eventId: _event!.id,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      eventTitle: _event!.title,
    );

    if (reg != null && mounted) {
      // Show confirmation dialog with direct link to QR pass
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.lightSuccess, size: 28),
              const SizedBox(width: 10),
              const Text('Spot Confirmed!'),
            ],
          ),
          content: Text(
            'You are registered for "${_event!.title}". Your entry pass is ready with your unique QR code.',
            style: AppTypography.manrope(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadEvent(); // Refresh capacity
              },
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/qr-pass/${reg.id}');
              },
              child: const Text('View Ticket Pass'),
            ),
          ],
        ),
      );
    } else if (regProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regProvider.errorMessage!),
          backgroundColor: AppColors.lightError,
        ),
      );
    }
  }

  void _showContactOrganizerDialog() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) {
      context.push('/login?reason=${Uri.encodeComponent('Contacting Organizer')}');
      return;
    }
    if (_event == null) return;

    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Message Organizer',
                          style: AppTypography.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ask questions or send comments regarding "${_event!.title}" directly to ${_event!.organizerName ?? "the organizer"}.',
                      style: AppTypography.manrope(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Your Question / Comment',
                      hint: 'Type your message or inquiry for the event host...',
                      controller: messageController,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your message' : null,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Send Message to Organizer',
                      icon: Icons.send_rounded,
                      isLoading: isSending,
                      onPressed: isSending
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSending = true);

                              final notifRepo = NotificationRepository();
                              await notifRepo.sendNotification(
                                userId: _event!.organizerId,
                                title: 'Attendee Question on "${_event!.title}"',
                                message: '${user.name}: ${messageController.text.trim()}',
                                type: 'announcement',
                                eventId: _event!.id,
                              );

                              if (modalCtx.mounted) {
                                Navigator.pop(modalCtx);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Message sent to organizer successfully!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final regProvider = context.watch<RegistrationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final feedbackProvider = context.watch<FeedbackProvider>();
    final galleryProvider = context.watch<GalleryProvider>();

    if (_isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Loading event details...'),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(_errorMessage ?? 'Event not found'),
        ),
      );
    }

    final event = _event!;
    final isRegistered = regProvider.isRegisteredForEvent(event.id);
    final userRegistration = regProvider.getRegistrationForEvent(event.id);
    final isFav = regProvider.isEventFavorited(event.id);
    final galleryPhotos = galleryProvider.getGalleryForEvent(event.id);
    final reviews = feedbackProvider.getFeedbackForEvent(event.id);
    final avgRating = feedbackProvider.getAverageRating(event.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? const Color(0xFFFF4B6E) : Colors.white,
                  ),
                  onPressed: () {
                    if (authProvider.currentUser != null) {
                      regProvider.toggleFavorite(
                        userId: authProvider.currentUser!.id,
                        eventId: event.id,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav ? 'Removed from Saved Events' : 'Saved to Favorites!',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      context.push('/login?reason=${Uri.encodeComponent('Saved Events')}');
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: event.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CategoryChip(category: event.category),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Event Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRegistered) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.green : AppColors.lightSuccess).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: (isDark ? Colors.green : AppColors.lightSuccess).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.lightSuccess, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOU ARE REGISTERED',
                                  style: AppTypography.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.greenAccent : AppColors.lightSuccess,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Your digital entry pass with QR code is ready.',
                                  style: AppTypography.manrope(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final reg = userRegistration ?? regProvider.getRegistrationForEvent(event.id);
                              if (reg != null) {
                                context.push('/qr-pass/${reg.id}');
                              } else {
                                context.push('/attendee/my-events');
                              }
                            },
                            child: const Text('View Pass', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Status & Capacity Summary Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: event.status),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFECE4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${event.registeredCount} / ${event.maxParticipants} Registered',
                          style: AppTypography.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Logistics Info Card (Date, Time, Location)
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                size: 22,
                                color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatter.formatEventDate(event.date),
                                    style: AppTypography.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    '${event.startTime} - ${event.endTime}',
                                    style: AppTypography.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            MapLocationPickerDialog.show(
                              context,
                              initialLocation: event.location,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 22,
                                    color: isDark ? AppColors.darkAccent : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Location & Venue',
                                            style: AppTypography.manrope(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: primaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.open_in_new_rounded,
                                            size: 13,
                                            color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        event.location,
                                        style: AppTypography.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About this Event',
                    style: AppTypography.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: AppTypography.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: primaryTextColor,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Event Rules & Guidelines (if any)
                  if (event.rules != null && event.rules!.isNotEmpty) ...[
                    Text(
                      'Guidelines & Requirements',
                      style: AppTypography.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF3EFE6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.rule_rounded, size: 20, color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              event.rules!,
                              style: AppTypography.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: primaryTextColor,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Organizer Info Card
                  Text(
                    'Hosted By',
                    style: AppTypography.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                              child: Text(
                                (event.organizerName ?? 'O')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.organizerName ?? 'Verified Organizer',
                                    style: AppTypography.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  if (event.organizerEmail != null)
                                    Text(
                                      event.organizerEmail!,
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
                        OutlinedButton.icon(
                          icon: const Icon(Icons.chat_outlined, size: 16),
                          label: const Text('Ask Question / Message Organizer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                            side: BorderSide(
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _showContactOrganizerDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Event Gallery Section (if photos uploaded)
                  if (galleryPhotos.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Event Memories',
                          style: AppTypography.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/gallery/${event.id}'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: galleryPhotos.length,
                        itemBuilder: (context, idx) {
                          final item = galleryPhotos[idx];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: AppNetworkImage(
                              imageUrl: item.imageUrl,
                              width: 140,
                              height: 110,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Feedback Section
                  if (reviews.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendee Reviews (${avgRating.toStringAsFixed(1)} ★)',
                          style: AppTypography.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...reviews.take(3).map((fb) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    fb.userName ?? 'Attendee',
                                    style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Row(
                                    children: List.generate(
                                      fb.rating,
                                      (_) => const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    ),
                                  ),
                                ],
                              ),
                              if (fb.comment != null && fb.comment!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  fb.comment!,
                                  style: AppTypography.manrope(fontSize: 12.5, color: secondaryTextColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 60), // Spacing for floating bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: isRegistered
            ? (event.isCompleted
                ? Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'View Pass',
                          variant: AppButtonVariant.outlined,
                          onPressed: () {
                            final reg = userRegistration ?? regProvider.getRegistrationForEvent(event.id);
                            if (reg != null) {
                              context.push('/qr-pass/${reg.id}');
                            } else {
                              context.push('/attendee/my-events');
                            }
                          },
                          icon: Icons.qr_code_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: 'Leave Review',
                          onPressed: () => context.push('/feedback/${event.id}'),
                          icon: Icons.rate_review_rounded,
                        ),
                      ),
                    ],
                  )
                : AppButton(
                    text: 'View Digital Ticket Pass',
                    onPressed: () {
                      final reg = userRegistration ?? regProvider.getRegistrationForEvent(event.id);
                      if (reg != null) {
                        context.push('/qr-pass/${reg.id}');
                      } else {
                        context.push('/attendee/my-events');
                      }
                    },
                    icon: Icons.qr_code_rounded,
                  ))
            : event.isCompleted
                ? const AppButton(
                    text: 'Registration Closed — Event Completed',
                    onPressed: null,
                    icon: Icons.event_busy_rounded,
                  )
                : event.isCancelled
                    ? const AppButton(
                        text: 'Event Cancelled',
                        onPressed: null,
                      )
                    : event.isPending
                        ? const AppButton(
                            text: 'Pending Approval — Registration Not Open',
                            onPressed: null,
                            icon: Icons.schedule_rounded,
                          )
                        : event.isFull
                            ? const AppButton(
                                text: 'Event Full (Capacity Reached)',
                                onPressed: null,
                              )
                            : event.isApproved
                                ? AppButton(
                                    text: 'Register Now (${event.remainingSeats} left)',
                                    onPressed: _onRegisterTapped,
                                    isLoading: regProvider.isLoading,
                                    icon: Icons.how_to_reg_rounded,
                                  )
                                : const AppButton(
                                    text: 'Registration Not Available',
                                    onPressed: null,
                                  ),
      ),
    );
  }
}
