import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/registration_provider.dart';
import '../../../providers/theme_provider.dart';

class HomeDiscoverScreen extends StatefulWidget {
  const HomeDiscoverScreen({super.key});

  @override
  State<HomeDiscoverScreen> createState() => _HomeDiscoverScreenState();
}

class _HomeDiscoverScreenState extends State<HomeDiscoverScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadDiscoverableEvents();
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<RegistrationProvider>().loadUserData(user.id, user.email);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? tempDate = eventProvider.selectedDate;
    String? tempLocation = eventProvider.selectedLocation;
    bool tempOnlyAvailable = eventProvider.onlyAvailable;
    final locationController = TextEditingController(text: tempLocation ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Events',
                        style: AppTypography.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          eventProvider.clearFilters();
                          _searchController.clear();
                          locationController.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Date Picker Field
                  Text(
                    'Event Date',
                    style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final firstDate = now.subtract(const Duration(days: 365));
                      final lastDate = now.add(const Duration(days: 365 * 2));
                      DateTime initial = tempDate ?? now;
                      if (initial.isBefore(firstDate)) initial = firstDate;
                      if (initial.isAfter(lastDate)) initial = lastDate;

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: firstDate,
                        lastDate: lastDate,
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempDate != null
                                ? DateFormatter.formatShortDate(tempDate)
                                : 'Any upcoming date',
                            style: TextStyle(
                              color: tempDate != null ? null : AppColors.lightTextSecondary,
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Field
                  Text(
                    'Location / Venue',
                    style: AppTypography.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    onChanged: (val) {
                      tempLocation = val.trim().isNotEmpty ? val.trim() : null;
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. San Francisco, Hall B...',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Only Available Seats Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Only with Available Seats'),
                    value: tempOnlyAvailable,
                    onChanged: (val) {
                      setModalState(() {
                        tempOnlyAvailable = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      final locText = locationController.text.trim();
                      final finalLocation = locText.isNotEmpty ? locText : null;
                      eventProvider.setDateFilter(tempDate);
                      eventProvider.setLocationFilter(finalLocation);
                      eventProvider.toggleOnlyAvailable(tempOnlyAvailable);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
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
    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final user = authProvider.currentUser;
    final userName = user != null && user.name.trim().isNotEmpty
        ? user.name.trim().split(" ").first
        : "Guest";

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => eventProvider.loadDiscoverableEvents(),
          child: CustomScrollView(
            slivers: [
              // Top Greeting & Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName 👋',
                              style: AppTypography.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Discover extraordinary events happening near you',
                              style: AppTypography.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar & Filter Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => eventProvider.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search events, topics, venues...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      eventProvider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: eventProvider.hasActiveFilters
                              ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                              : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEDEAE1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: eventProvider.hasActiveFilters
                                ? (isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent)
                                : primaryTextColor,
                          ),
                          onPressed: () => _showFilterModal(context),
                          tooltip: 'Filter Events',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter Horizontal Carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            'All Categories',
                            style: AppTypography.manrope(
                              fontSize: 12,
                              fontWeight: eventProvider.selectedCategory == 'all'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: eventProvider.selectedCategory == 'all',
                          onSelected: (_) => eventProvider.filterByCategory('all'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          selectedColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          labelStyle: TextStyle(
                            color: eventProvider.selectedCategory == 'all'
                                ? (isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent)
                                : primaryTextColor,
                          ),
                        ),
                      ),
                      ...AppConstants.categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: CategoryChip(
                            category: cat,
                            isSelected: eventProvider.selectedCategory == cat,
                            onSelected: (_) => eventProvider.filterByCategory(cat),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Active Filters Notice (if applied)
              if (eventProvider.hasActiveFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtered Results (${eventProvider.discoverableEvents.length})',
                          style: AppTypography.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            eventProvider.clearFilters();
                          },
                          child: Text(
                            'Clear Filters',
                            style: AppTypography.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Events Content List
              if (eventProvider.isLoading && eventProvider.discoverableEvents.isEmpty)
                const SliverToBoxAdapter(
                  child: EventListSkeleton(itemCount: 3),
                )
              else if (eventProvider.errorMessage != null)
                SliverFillRemaining(
                  child: ErrorView(
                    message: eventProvider.errorMessage!,
                    onRetry: () => eventProvider.loadDiscoverableEvents(),
                  ),
                )
              else if (eventProvider.discoverableEvents.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateView(
                    icon: Icons.event_busy_rounded,
                    title: 'No Events Found',
                    message: eventProvider.hasActiveFilters
                        ? 'Try modifying your search query or removing category/date filters.'
                        : 'There are currently no approved upcoming events. Check back soon!',
                    actionLabel: eventProvider.hasActiveFilters ? 'Clear Filters' : null,
                    onAction: eventProvider.hasActiveFilters
                        ? () {
                            _searchController.clear();
                            eventProvider.clearFilters();
                          }
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = eventProvider.discoverableEvents[index];
                        return _buildEventCard(context, event, isDark, primaryTextColor, secondaryTextColor);
                      },
                      childCount: eventProvider.discoverableEvents.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    EventModel event,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final regProvider = context.watch<RegistrationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFav = regProvider.isEventFavorited(event.id);
    final isRegistered = regProvider.isRegisteredForEvent(event.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: AppCard(
        onTap: () => context.push('/event-details/${event.id}'),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image Banner + Floating Category & Favorite Badges
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: event.imageUrl,
                  height: 170,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
                ),

                // Category Tag Top Left
                Positioned(
                  top: 12,
                  left: 12,
                  child: CategoryChip(category: event.category),
                ),

                // Favorite Heart Toggle Top Right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? const Color(0xFFFF4B6E) : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (authProvider.currentUser != null) {
                          regProvider.toggleFavorite(
                            userId: authProvider.currentUser!.id,
                            eventId: event.id,
                            userEmail: authProvider.currentUser!.email,
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
                      tooltip: 'Save Event',
                    ),
                  ),
                ),

                // Registered Badge Overlay if already registered
                if (isRegistered)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Registered',
                            style: AppTypography.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Completed Badge Overlay
                if (event.isCompleted)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF555045) : const Color(0xFF6B6458),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: AppTypography.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title (Manrope 600)
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date and Time Row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatEventSchedule(event.date, event.startTime, event.endTime),
                        style: AppTypography.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location Row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: secondaryTextColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Capacity & Seats Remaining Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.isCompleted
                            ? 'Event Concluded'
                            : event.isFull
                                ? 'Event is Full'
                                : '${event.remainingSeats} seats available',
                        style: AppTypography.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: event.isCompleted
                              ? secondaryTextColor
                              : event.isFull
                                  ? (isDark ? AppColors.darkError : AppColors.lightError)
                                  : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: AppTypography.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
