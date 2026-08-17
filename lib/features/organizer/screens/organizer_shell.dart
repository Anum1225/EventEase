import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_navigation_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class OrganizerShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const OrganizerShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
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
    final indigoAccent = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: ModernFloatingNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onItemTapped,
        activeColor: indigoAccent,
        items: [
          const ModernNavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          const ModernNavItem(
            icon: Icons.add_circle_outline_rounded,
            selectedIcon: Icons.add_circle_rounded,
            label: 'New Event',
          ),
          const ModernNavItem(
            icon: Icons.qr_code_scanner_rounded,
            selectedIcon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
          ),
          const ModernNavItem(
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_rounded,
            label: 'Roster',
          ),
          ModernNavItem(
            icon: Icons.star_outline_rounded,
            selectedIcon: Icons.star_rounded,
            label: 'Reviews',
            badgeCount: unreadCount,
          ),
        ],
      ),
    );
  }
}
