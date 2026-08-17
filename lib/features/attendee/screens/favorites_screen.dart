import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/event_model.dart';
import '../../../repositories/event_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/registration_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _eventRepo = EventRepository();
  final List<EventModel> _cachedEvents = [];
  bool _isLoading = true;
  bool _isFetching = false;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFavorites();
      }
    });
  }

  Future<void> _loadFavorites() async {
    if (_isFetching) return;
    _isFetching = true;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _cachedEvents.clear();
          _isLoading = false;
          _isFetching = false;
        });
      }
      return;
    }

    final regProvider = context.read<RegistrationProvider>();
    await regProvider.loadUserData(user.id);

    final Set<String> favIds = regProvider.favoriteEventIds;
    final List<EventModel> loaded = [];

    for (final id in favIds) {
      final ev = await _eventRepo.getEventById(id);
      if (ev != null) loaded.add(ev);
    }

    if (mounted) {
      setState(() {
        _cachedEvents.clear();
        _cachedEvents.addAll(loaded);
        _loadedUserId = user.id;
        _isLoading = false;
        _isFetching = false;
      });
    } else {
      _isFetching = false;
    }
  }

  void _syncMissingFavorites(RegistrationProvider regProvider, String userId) {
    if (_loadedUserId != userId) {
      _loadFavorites();
      return;
    }

    final currentFavIds = regProvider.favoriteEventIds;

    // Remove cached events that are no longer favorited
    _cachedEvents.removeWhere((e) => !currentFavIds.contains(e.id));

    // Fetch any missing events that are favorited but not yet cached
    final existingIds = _cachedEvents.map((e) => e.id).toSet();
    final missingIds = currentFavIds.difference(existingIds);

    if (missingIds.isNotEmpty && !_isFetching) {
      _fetchMissingEvents(missingIds);
    }
  }

  Future<void> _fetchMissingEvents(Set<String> missingIds) async {
    _isFetching = true;
    final List<EventModel> newItems = [];
    for (final id in missingIds) {
      final ev = await _eventRepo.getEventById(id);
      if (ev != null) newItems.add(ev);
    }
    if (mounted) {
      setState(() {
        _cachedEvents.addAll(newItems);
        _isFetching = false;
      });
    } else {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final authProvider = context.watch<AuthProvider>();
    final regProvider = context.watch<RegistrationProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Saved Events',
            style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: EmptyStateView(
          icon: Icons.lock_outline_rounded,
          title: 'Sign In Required',
          message: 'Please log in to save your favorite events and sync them across devices.',
          actionLabel: 'Sign In Now',
          onAction: () => context.push('/login?reason=${Uri.encodeComponent('Saved Events')}'),
        ),
      );
    }

    _syncMissingFavorites(regProvider, user.id);

    // Filter displayed events strictly to active favoriteEventIds
    final displayedEvents = _cachedEvents
        .where((e) => regProvider.isEventFavorited(e.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Events',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EventListSkeleton(itemCount: 2),
            )
          : displayedEvents.isEmpty
              ? EmptyStateView(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Saved Events Yet',
                  message: 'Bookmark interesting events while browsing by tapping the heart icon to quickly access them later.',
                  actionLabel: 'Discover Events',
                  onAction: () => context.go('/attendee'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: displayedEvents.length,
                  itemBuilder: (context, index) {
                    final event = displayedEvents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: AppCard(
                        onTap: () => context.push('/event-details/${event.id}'),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppNetworkImage(
                              imageUrl: event.imageUrl,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CategoryChip(
                                    category: event.category,
                                    fontSize: 10,
                                    iconSize: 12,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.title,
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
                                        DateFormatter.formatShortDate(event.date),
                                        style: AppTypography.manrope(fontSize: 12, color: secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_rounded, color: Color(0xFFFF4B6E), size: 22),
                              onPressed: () async {
                                await regProvider.toggleFavorite(
                                  userId: user.id,
                                  eventId: event.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Removed from Saved Events'),
                                      duration: Duration(seconds: 2),
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
                ),
    );
  }
}
