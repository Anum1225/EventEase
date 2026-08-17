import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<NotificationProvider>().loadUserNotifications(user.id);
      }
    });
  }

  void _showPreferencesDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Map<String, bool> prefs = Map.from(user.notificationPreferences);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Text(
            'Notification Preferences',
            style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Event Reminders (24h prior)'),
                  value: prefs['reminders'] ?? true,
                  onChanged: (val) => setDialogState(() => prefs['reminders'] = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Organizer Announcements'),
                  value: prefs['announcements'] ?? true,
                  onChanged: (val) => setDialogState(() => prefs['announcements'] = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Event Detail Updates'),
                  value: prefs['updates'] ?? true,
                  onChanged: (val) => setDialogState(() => prefs['updates'] = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Post-Event Feedback Requests'),
                  value: prefs['feedback'] ?? true,
                  onChanged: (val) => setDialogState(() => prefs['feedback'] = val),
                ),
                const Divider(),
                Text(
                  'Per institutional requirements (SRS 1.6.9), critical cancellation alerts cannot be disabled.',
                  style: AppTypography.manrope(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await authProvider.updateNotificationPreferences(prefs);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification preferences saved! 🔔'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'registration_confirm':
        return Icons.check_circle_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'event_update':
        return Icons.edit_calendar_rounded;
      case 'event_cancelled':
        return Icons.cancel_rounded;
      case 'feedback_request':
        return Icons.rate_review_rounded;
      case 'announcement':
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _getColorForType(String type, bool isDark) {
    switch (type) {
      case 'registration_confirm':
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case 'event_cancelled':
        return isDark ? AppColors.darkError : AppColors.lightError;
      case 'reminder':
      case 'event_update':
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
      case 'announcement':
      default:
        return isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final notifProvider = context.watch<NotificationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: EmptyStateView(
          icon: Icons.lock_outline_rounded,
          title: 'Sign In Required',
          message: 'Please log in to receive instant event reminders, announcements, and entry updates.',
          actionLabel: 'Sign In Now',
          onAction: () => context.push('/login?reason=${Uri.encodeComponent('Notifications')}'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Preferences',
            onPressed: () => _showPreferencesDialog(context),
          ),
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(user.id),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifProvider.isLoading
          ? const LoadingView(message: 'Loading your alerts...')
          : notifProvider.notifications.isEmpty
              ? const EmptyStateView(
                  icon: Icons.notifications_off_outlined,
                  title: 'All Caught Up!',
                  message: 'You have no new alerts or notifications at this time.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifProvider.notifications[index];
                    final iconColor = _getColorForType(notif.type, isDark);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AppCard(
                        onTap: () {
                          notifProvider.markAsRead(notif.id);
                          if (notif.eventId != null) {
                            context.push('/event-details/${notif.eventId}');
                          }
                        },
                        padding: const EdgeInsets.all(14),
                        customColor: notif.isRead
                            ? null
                            : (isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.lightAccent.withValues(alpha: 0.08)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForType(notif.type),
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: AppTypography.manrope(
                                            fontSize: 14,
                                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ),
                                      if (!notif.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: AppTypography.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: notif.isRead ? secondaryTextColor : primaryTextColor,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormatter.formatRelative(notif.createdAt),
                                    style: AppTypography.manrope(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
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
