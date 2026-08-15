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
  List<EventModel> _favoriteEvents = [];
  bool _isLoading = true;

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
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final regProvider = context.read<RegistrationProvider>();
    await regProvider.loadUserData(user.id);

    final favIds = regProvider.favoriteEventIds;
    final List<EventModel> loaded = [];

    for (final id in favIds) {
      final ev = await _eventRepo.getEventById(id);
      if (ev != null) loaded.add(ev);
    }

    if (mounted) {
      setState(() {
        _favoriteEvents = loaded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final authProvider = context.watch<AuthProvider>();
    final regProvider = context.watch<RegistrationProvider>();

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
          : _favoriteEvents.isEmpty
              ? EmptyStateView(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Saved Events Yet',
                  message: 'Bookmark interesting events while browsing to quickly access them later.',
                  actionLabel: 'Discover Events',
                  onAction: () => context.go('/attendee'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _favoriteEvents.length,
                  itemBuilder: (context, index) {
                    final event = _favoriteEvents[index];
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
                                if (authProvider.currentUser != null) {
                                  await regProvider.toggleFavorite(
                                    userId: authProvider.currentUser!.id,
                                    eventId: event.id,
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _favoriteEvents.removeWhere((e) => e.id == event.id);
                                    });
                                  }
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
