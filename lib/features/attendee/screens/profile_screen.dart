import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../auth/screens/two_factor_verification_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  final _profileFormKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    final phoneText = user?.phone?.isNotEmpty == true ? user!.phone! : '+92 ';
    _phoneController = TextEditingController(text: phoneText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        if (!kIsWeb) {
          _pickedImageFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_profileFormKey.currentState?.validate() == false) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      newProfileImageFile: _pickedImageFile,
      newProfileImageBytes: _pickedImageBytes,
    );

    if (success && mounted) {
      setState(() {
        _isEditing = false;
        _pickedImageFile = null;
        _pickedImageBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSubmitting = false;
        String? localError;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final isDark = Theme.of(modalContext).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
            final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle Bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Change Password',
                        style: AppTypography.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your current password and choose a new secure password.',
                        style: AppTypography.manrope(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (localError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: isDark ? AppColors.darkError : AppColors.lightError,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localError!,
                                  style: AppTypography.manrope(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkError : AppColors.lightError,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      AppTextField(
                        label: 'Current Password',
                        controller: currentPassController,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'New Password',
                        controller: newPassController,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Confirm New Password',
                        controller: confirmPassController,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        validator: (val) => Validators.confirmPassword(val, newPassController.text),
                      ),

                      // Generous vertical spacing positioning the button down comfortably
                      const SizedBox(height: 28),

                      AppButton(
                        text: 'Update Password',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() {
                                  isSubmitting = true;
                                  localError = null;
                                });

                                final authProvider = context.read<AuthProvider>();
                                final success = await authProvider.changePassword(
                                  currentPassController.text,
                                  newPassController.text,
                                );

                                if (modalContext.mounted) {
                                  if (success) {
                                    Navigator.pop(modalContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password updated successfully!'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  } else {
                                    setModalState(() {
                                      isSubmitting = false;
                                      localError = authProvider.errorMessage ?? 'Failed to update password. Please check your current password.';
                                    });
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Cancel',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleTwoFactorSetting(bool enable) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    if (enable) {
      final otp = await authProvider.sendTwoFactorEmailOtp(
        user.email,
        userName: user.name,
        actionType: 'Enable 2FA Protection',
      );
      if (!mounted) return;
      final verified = await TwoFactorVerificationDialog.show(
        context,
        email: user.email,
        generatedOtp: otp,
        onResendOtp: () async => authProvider.sendTwoFactorEmailOtp(
          user.email,
          userName: user.name,
          actionType: 'Enable 2FA Protection',
        ),
        onVerifyOtp: (code) async => authProvider.verifyTwoFactorOtp(user.email, code),
      );

      if (verified == true && mounted) {
        await authProvider.toggleTwoFactor(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-Factor Authentication has been successfully enabled.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      final confirm = await ConfirmationDialog.show(
        context,
        title: 'Disable 2FA?',
        message: 'Are you sure you want to turn off Two-Factor Authentication? Your account will be less secure.',
        confirmLabel: 'Disable 2FA',
        isDestructive: true,
      );

      if (confirm && mounted) {
        await authProvider.toggleTwoFactor(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-Factor Authentication disabled.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile & Settings',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Role Badge Header
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                    backgroundImage: _pickedImageBytes != null
                        ? MemoryImage(_pickedImageBytes!) as ImageProvider
                        : (_pickedImageFile != null && !kIsWeb)
                            ? FileImage(_pickedImageFile!) as ImageProvider
                            : (user?.profileImage != null && user!.profileImage!.isNotEmpty
                                ? (user.profileImage!.startsWith('data:image/')
                                    ? MemoryImage(base64Decode(user.profileImage!.split(',').last)) as ImageProvider
                                    : NetworkImage(user.profileImage!))
                                : null),
                    child: (_pickedImageBytes == null && _pickedImageFile == null && (user?.profileImage == null || user!.profileImage!.isEmpty))
                        ? Text(
                            (user?.name ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkOnAccent : AppColors.lightOnAccent,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              user?.name ?? 'Guest',
              style: AppTypography.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'Sign in to sync your tickets & saved events',
              style: AppTypography.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user?.role == AppConstants.roleAdmin
                    ? (isDark ? AppColors.darkAdminAccent.withValues(alpha: 0.2) : Colors.black)
                    : user?.role == AppConstants.roleOrganizer
                        ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                        : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (user?.role ?? 'GUEST').toUpperCase(),
                style: TextStyle(
                  color: user?.role == AppConstants.roleAdmin ? Colors.white : (isDark ? Colors.black : Colors.white),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Edit Form or Details Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  if (_isEditing) ...[
                    Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Full Name',
                            controller: _nameController,
                            validator: (v) => Validators.required(v, 'Name'),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Pakistani Phone Number',
                            hint: '+92 300 1234567',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Cancel',
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _nameController.text = user?.name ?? '';
                                      _phoneController.text = user?.phone ?? '';
                                      _pickedImageFile = null;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppButton(
                                  text: 'Save Changes',
                                  onPressed: _saveProfile,
                                  isLoading: authProvider.isLoading,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Name'),
                      subtitle: Text(user?.name ?? 'Not set'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? 'Not set'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      subtitle: Text(user?.phone?.isNotEmpty == true ? user!.phone! : 'Not provided'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Role Switcher shortcut (if user has organizer or admin privileges)
            if (user?.role == AppConstants.roleOrganizer || user?.role == AppConstants.roleAdmin) ...[
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch Workspace',
                      style: AppTypography.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (user?.role == AppConstants.roleOrganizer)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.dashboard_customize_rounded, color: AppColors.lightOrganizerAccent),
                        title: const Text('Organizer Dashboard'),
                        subtitle: const Text('Manage your events, scan attendance, and view metrics'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/organizer'),
                      ),
                    if (user?.role == AppConstants.roleAdmin)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.lightError),
                        title: const Text('Admin Console'),
                        subtitle: const Text('System approvals, users, events, and reports'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/admin'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // App Settings Card (Security, Theme, About Us, Contact Us)
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.shield_outlined,
                      color: user?.isTwoFactorEnabled == true
                          ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                          : null,
                    ),
                    title: const Text('Two-Factor Authentication (2FA)'),
                    subtitle: Text(
                      user?.isTwoFactorEnabled == true
                          ? 'Protected with 6-digit verification code'
                          : 'Extra security for your login session',
                      style: TextStyle(
                        color: user?.isTwoFactorEnabled == true
                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            : null,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Switch(
                      value: user?.isTwoFactorEnabled ?? false,
                      onChanged: (val) => _toggleTwoFactorSetting(val),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                    title: const Text('Appearance / Theme'),
                    subtitle: Text(themeProvider.themeMode == ThemeMode.system ? 'System Default' : (isDark ? 'Dark Mode' : 'Light Mode')),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About EventEase'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/about-us'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline_rounded),
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/contact-us'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Log In / Log Out Action Button
            if (user == null)
              AppButton(
                text: 'Log In / Sign In',
                icon: Icons.login_rounded,
                onPressed: () => context.push('/login'),
              )
            else
              AppButton(
                text: 'Log Out',
                variant: AppButtonVariant.outlined,
                icon: Icons.logout_rounded,
                onPressed: () async {
                  final confirm = await ConfirmationDialog.show(
                    context,
                    title: 'Sign Out?',
                    message: 'Are you sure you want to sign out of EventEase?',
                    confirmLabel: 'Sign Out',
                    isDestructive: true,
                  );
                  if (confirm && context.mounted) {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
