import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_navigation_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class AdminShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<NotificationProvider>().subscribeToUserNotifications(user.id);
      }
    });
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: ModernFloatingNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
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
