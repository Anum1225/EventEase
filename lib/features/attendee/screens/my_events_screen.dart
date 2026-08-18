import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/registration_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/registration_provider.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<RegistrationProvider>().loadUserData(user.id, user.email);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final regProvider = context.watch<RegistrationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Registered Events',
            style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: EmptyStateView(
          icon: Icons.lock_outline_rounded,
          title: 'Sign In Required',
          message: 'Please log in to view your registered events, access your digital entry passes, and manage tickets.',
          actionLabel: 'Sign In Now',
          onAction: () => context.push('/login?reason=${Uri.encodeComponent('My Events')}'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Registered Events',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          labelColor: primaryTextColor,
          unselectedLabelColor: secondaryTextColor,
          labelStyle: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: 'Upcoming (${regProvider.upcomingRegistrations.length})'),
            Tab(text: 'Completed (${regProvider.completedRegistrations.length})'),
            Tab(text: 'Cancelled (${regProvider.cancelledRegistrations.length})'),
          ],
        ),
      ),
      body: regProvider.isLoading && regProvider.registrations.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EventListSkeleton(itemCount: 2),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRegistrationList(
                  context,
                  regProvider.upcomingRegistrations,
                  'No Upcoming Events',
                  'You haven’t registered for any upcoming events yet. Discover exciting experiences on the home tab!',
                  isUpcoming: true,
                  user: user,
                ),
                _buildRegistrationList(
                  context,
                  regProvider.completedRegistrations,
                  'No Completed Events',
                  'Events you attend will appear here once they conclude.',
                  isCompleted: true,
                  user: user,
                ),
                _buildRegistrationList(
                  context,
                  regProvider.cancelledRegistrations,
                  'No Cancelled Events',
                  'Any cancelled registrations will be archived here.',
                  isCancelled: true,
                  user: user,
                ),
              ],
            ),
    );
  }

  Widget _buildRegistrationList(
    BuildContext context,
    List<RegistrationModel> list,
    String emptyTitle,
    String emptyMessage, {
    bool isUpcoming = false,
    bool isCompleted = false,
    bool isCancelled = false,
    dynamic user,
  }) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await context.read<RegistrationProvider>().loadUserData(user.id, user.email);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: EmptyStateView(
              icon: isCancelled ? Icons.event_busy_rounded : Icons.confirmation_number_outlined,
              title: emptyTitle,
              message: emptyMessage,
              actionLabel: isUpcoming ? 'Discover Events' : null,
              onAction: isUpcoming ? () => context.go('/attendee') : null,
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await context.read<RegistrationProvider>().loadUserData(user.id, user.email);
        }
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
        final reg = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: AppCard(
            onTap: () => context.push('/qr-pass/${reg.id}'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small thumbnail
                    AppNetworkImage(
                      imageUrl: reg.eventBanner,
                      width: 70,
                      height: 70,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 14),

                    // Title & logistics
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reg.eventCategory != null)
                            CategoryChip(
                              category: reg.eventCategory!,
                              fontSize: 10,
                              iconSize: 12,
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            reg.eventTitle ?? 'Event',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: secondaryTextColor),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatShortDate(reg.eventDate),
                                style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Card Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        StatusBadge(status: reg.status),
                        if (isCompleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF24221D) : const Color(0xFFEDEAE1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag_rounded, size: 12, color: secondaryTextColor),
                                const SizedBox(width: 3),
                                Text(
                                  'Concluded',
                                  style: AppTypography.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (isUpcoming) ...[
                          TextButton(
                            onPressed: () async {
                              final confirm = await ConfirmationDialog.show(
                                context,
                                title: 'Cancel Registration?',
                                message: 'Are you sure you want to cancel your spot for "${reg.eventTitle}"? This will release your seat to other attendees.',
                                confirmLabel: 'Yes, Cancel',
                                isDestructive: true,
                              );
                              if (confirm && context.mounted && user != null) {
                                await context.read<RegistrationProvider>().cancelRegistration(
                                  registrationId: reg.id,
                                  eventId: reg.eventId,
                                  userId: user.id,
                                );
                              }
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? AppColors.darkError : AppColors.lightError,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: const Size(0, 36),
                            ),
                            onPressed: () => context.push('/qr-pass/${reg.id}'),
                            icon: const Icon(Icons.qr_code_rounded, size: 16),
                            label: const Text('Pass', style: TextStyle(fontSize: 13)),
                          ),
                        ] else if (isCompleted) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(0, 34),
                            ),
                            onPressed: () => context.push('/feedback/${reg.eventId}'),
                            icon: const Icon(Icons.star_outline_rounded, size: 15),
                            label: const Text('Review', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}
