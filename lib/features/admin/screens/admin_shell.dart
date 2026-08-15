import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_navigation_bar.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({
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
    final adminAccent = isDark ? AppColors.darkAccent : const Color(0xFF1E293B);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ModernFloatingNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        activeColor: adminAccent,
        items: const [
          ModernNavItem(
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings_rounded,
            label: 'Overview',
          ),
          ModernNavItem(
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check_rounded,
            label: 'Approvals',
          ),
          ModernNavItem(
            icon: Icons.manage_accounts_outlined,
            selectedIcon: Icons.manage_accounts_rounded,
            label: 'Users',
          ),
          ModernNavItem(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
            label: 'Events',
          ),
          ModernNavItem(
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics_rounded,
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
