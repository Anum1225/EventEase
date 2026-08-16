import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+92 ');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _applyAsOrganizer = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      applyAsOrganizer: _applyAsOrganizer,
    );

    if (success && mounted) {
      if (_applyAsOrganizer) {
        context.go('/organizer-pending');
      } else {
        context.go('/attendee');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: AppTypography.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join the EventEase community',
                      textAlign: TextAlign.center,
                      style: AppTypography.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (authProvider.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkError : AppColors.lightError)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? AppColors.darkError : AppColors.lightError)
                                      .withValues(alpha: 0.4),
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
                                      authProvider.errorMessage!,
                                      style: AppTypography.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkError : AppColors.lightError,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          AppTextField(
                            label: 'Full Name',
                            hint: 'e.g. Jane Doe',
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (val) => Validators.required(val, 'Full Name'),
                          ),
                          const SizedBox(height: 14),

                          AppTextField(
                            label: 'Email Address',
                            hint: 'name@domain.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.email_outlined,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 14),

                          AppTextField(
                            label: 'Pakistani Phone Number',
                            hint: '+92 300 1234567',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.phone_outlined,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 14),

                          AppTextField(
                            label: 'Password',
                            hint: 'Minimum 6 characters',
                            controller: _passwordController,
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: Validators.password,
                          ),
                          const SizedBox(height: 14),

                          AppTextField(
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_clock_outlined,
                            validator: (val) => Validators.confirmPassword(val, _passwordController.text),
                          ),
                          const SizedBox(height: 16),

                          // Organizer Application Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF3EFE6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeTrackColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                              title: Text(
                                'Apply as an Event Organizer',
                                style: AppTypography.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTextColor,
                                ),
                              ),
                              subtitle: Text(
                                'Organizer accounts require administrator review prior to publishing events.',
                                style: AppTypography.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: secondaryTextColor,
                                ),
                              ),
                              value: _applyAsOrganizer,
                              onChanged: (val) {
                                setState(() {
                                  _applyAsOrganizer = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 22),

                          AppButton(
                            text: 'Create Account',
                            onPressed: _submit,
                            isLoading: authProvider.isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: AppTypography.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
