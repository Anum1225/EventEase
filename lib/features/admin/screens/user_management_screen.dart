import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
      context.read<AdminProvider>().loadPendingOrganizers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    context.read<AdminProvider>().loadUsers(
      role: _selectedRoleFilter == 'all' ? null : _selectedRoleFilter,
      query: _searchController.text,
    );
  }

  void _showRejectOrganizerDialog(BuildContext context, UserModel user) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text(
          'Reject Organizer Application',
          style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Specify why ${user.name}\'s organizer application is being rejected. Their account will revert to attendee role.',
                style: AppTypography.manrope(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Unverified organizational credentials...',
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Reason is required' : null,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightError),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await context.read<AdminProvider>().rejectOrganizer(
                user.id,
                reasonController.text.trim(),
                user.name,
              );
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Organizer application rejected.')),
                );
              }
            },
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final adminProvider = context.watch<AdminProvider>();
    final users = adminProvider.users;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User & Role Directory',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _onFilterChanged(),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Role Filter Tabs
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildRoleFilterChip('All Users', 'all', isDark, primaryTextColor),
                _buildRoleFilterChip('Pending Organizers', AppConstants.roleOrganizerPending, isDark, primaryTextColor),
                _buildRoleFilterChip('Organizers', AppConstants.roleOrganizer, isDark, primaryTextColor),
                _buildRoleFilterChip('Attendees', AppConstants.roleAttendee, isDark, primaryTextColor),
                _buildRoleFilterChip('Admins', AppConstants.roleAdmin, isDark, primaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // User List
          Expanded(
            child: adminProvider.isLoading
                ? const LoadingView(message: 'Loading user accounts...')
                : users.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.person_search_rounded,
                        title: 'No Users Found',
                        message: 'No user accounts match the current filter or search criteria.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, idx) {
                          final user = users[idx];
                          final isPendingOrg = user.role == AppConstants.roleOrganizerPending;
                          final isDeactivated = user.status == AppConstants.userStatusDeactivated;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: user.isAdmin
                                            ? Colors.black
                                            : user.isOrganizer
                                                ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                                                : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEDEAE1)),
                                        child: Text(
                                          (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                                          style: TextStyle(
                                            color: (user.isAdmin || user.isOrganizer) ? Colors.white : primaryTextColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: AppTypography.manrope(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: primaryTextColor,
                                                    ),
                                                  ),
                                                ),
                                                StatusBadge(
                                                  status: user.status,
                                                  fontSize: 10,
                                                  iconSize: 11,
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              user.email,
                                              style: AppTypography.manrope(fontSize: 12.5, color: secondaryTextColor),
                                            ),
                                            if (user.phone != null && user.phone!.isNotEmpty)
                                              Text(
                                                'Phone: ${user.phone}',
                                                style: AppTypography.manrope(fontSize: 11.5, color: secondaryTextColor),
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE9E6DC),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'ROLE: ${user.role.toUpperCase()}',
                                                    style: AppTypography.manrope(fontSize: 10, fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Joined: ${DateFormatter.formatShortDate(user.createdAt)}',
                                                  style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Pending Organizer Application Approval Box
                                  if (isPendingOrg) ...[
                                    const Divider(height: 18),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline_rounded, size: 16, color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'Applied for Organizer role privileges.',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  side: const BorderSide(color: AppColors.lightError),
                                                ),
                                                onPressed: () => _showRejectOrganizerDialog(context, user),
                                                child: const Text('Reject', style: TextStyle(color: AppColors.lightError, fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                ),
                                                onPressed: () async {
                                                  final success = await adminProvider.approveOrganizer(user.id, user.email, user.name);
                                                  if (success && context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('${user.name} approved as organizer.')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Account Deactivation Toggle (Admins cannot deactivate fellow admins)
                                  if (!user.isAdmin) ...[
                                    const Divider(height: 18),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: Icon(
                                            isDeactivated ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                                            size: 15,
                                            color: isDeactivated ? AppColors.lightSuccess : AppColors.lightError,
                                          ),
                                          label: Text(
                                            isDeactivated ? 'Reactivate Account' : 'Deactivate Account',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDeactivated ? AppColors.lightSuccess : AppColors.lightError,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final confirm = await ConfirmationDialog.show(
                                              context,
                                              title: isDeactivated ? 'Reactivate Account?' : 'Deactivate Account?',
                                              message: isDeactivated
                                                  ? 'Allow ${user.name} to log in and participate in events again?'
                                                  : 'Deactivating ${user.name} will immediately block them from signing in.',
                                              confirmLabel: isDeactivated ? 'Reactivate' : 'Deactivate',
                                              isDestructive: !isDeactivated,
                                            );
                                            if (confirm && context.mounted) {
                                              final success = await adminProvider.toggleUserStatus(user.id, !isDeactivated);
                                              if (success && context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      isDeactivated
                                                          ? '${user.name} reactivated successfully.'
                                                          : '${user.name} deactivated successfully.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String roleValue, bool isDark, Color primaryColor) {
    final isSelected = _selectedRoleFilter == roleValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedRoleFilter = roleValue);
          _onFilterChanged();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        selectedColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        labelStyle: TextStyle(
          color: isSelected
              ? (isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent)
              : primaryColor,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
