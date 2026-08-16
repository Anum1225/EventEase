import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_navigation_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class AttendeeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AttendeeShell({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ModernFloatingNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        items: [
          const ModernNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
            label: 'Discover',
          ),
          const ModernNavItem(
            icon: Icons.confirmation_number_outlined,
            selectedIcon: Icons.confirmation_number_rounded,
            label: 'My Events',
          ),
          const ModernNavItem(
            icon: Icons.favorite_outline_rounded,
            selectedIcon: Icons.favorite_rounded,
            label: 'Saved',
          ),
          ModernNavItem(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
            label: 'Alerts',
            badgeCount: unreadCount,
          ),
          const ModernNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
