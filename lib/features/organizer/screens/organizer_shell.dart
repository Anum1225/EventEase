import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_navigation_bar.dart';

class OrganizerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const OrganizerShell({
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
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ModernFloatingNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        activeColor: indigoAccent,
        items: const [
          ModernNavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          ModernNavItem(
            icon: Icons.add_circle_outline_rounded,
            selectedIcon: Icons.add_circle_rounded,
            label: 'New Event',
          ),
          ModernNavItem(
            icon: Icons.qr_code_scanner_rounded,
            selectedIcon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
          ),
          ModernNavItem(
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_rounded,
            label: 'Roster',
          ),
          ModernNavItem(
            icon: Icons.star_outline_rounded,
            selectedIcon: Icons.star_rounded,
            label: 'Reviews',
          ),
        ],
      ),
    );
  }
}
