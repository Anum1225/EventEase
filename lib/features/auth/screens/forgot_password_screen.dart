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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordReset(_emailController.text.trim());

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: _emailSent
                  ? AppCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_read_rounded,
                              size: 48,
                              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Reset Link Sent',
                            style: AppTypography.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We have dispatched password recovery instructions to ${_emailController.text.trim()}. Please check your inbox and spam folders.',
                            textAlign: TextAlign.center,
                            style: AppTypography.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: secondaryTextColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Back to Sign In',
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFECE4),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 36,
                                color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Reset Password',
                            textAlign: TextAlign.center,
                            style: AppTypography.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Enter the email associated with your account and we'll send you a password reset link.",
                            textAlign: TextAlign.center,
                            style: AppTypography.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 24),

                          AppCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (authProvider.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: (isDark ? AppColors.darkError : AppColors.lightError)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      authProvider.errorMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkError : AppColors.lightError,
                                      ),
                                    ),
                                  ),
                                ],
                                AppTextField(
                                  label: 'Email Address',
                                  hint: 'name@domain.com',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 20),
                                AppButton(
                                  text: 'Send Reset Link',
                                  onPressed: _submit,
                                  isLoading: authProvider.isLoading,
                                ),
                              ],
                            ),
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
