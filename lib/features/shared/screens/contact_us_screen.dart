import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contact_provider.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser;
    final contactProvider = context.read<ContactProvider>();

    final success = await contactProvider.submitMessage(
      userId: user?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final contactProvider = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _submitted
                ? AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_read_rounded, size: 54, color: AppColors.lightSuccess),
                        const SizedBox(height: 16),
                        Text(
                          'Message Dispatched',
                          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thank you for reaching out! Our institutional support team will review your inquiry and respond shortly.',
                          textAlign: TextAlign.center,
                          style: AppTypography.manrope(fontSize: 14, color: secondaryTextColor),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Send Another Inquiry',
                          variant: AppButtonVariant.outlined,
                          onPressed: () {
                            setState(() {
                              _submitted = false;
                              _subjectController.clear();
                              _messageController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get in Touch',
                          textAlign: TextAlign.center,
                          style: AppTypography.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Have questions, feedback, or need technical assistance? Fill out the form below.',
                          textAlign: TextAlign.center,
                          style: AppTypography.manrope(fontSize: 13.5, color: secondaryTextColor),
                        ),
                        const SizedBox(height: 24),

                        AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                label: 'Your Name *',
                                hint: 'e.g. Alex Johnson',
                                controller: _nameController,
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => Validators.required(v, 'Name'),
                              ),
                              const SizedBox(height: 14),

                              AppTextField(
                                label: 'Email Address *',
                                hint: 'name@domain.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 14),

                              AppTextField(
                                label: 'Subject *',
                                hint: 'e.g. Question regarding event pass check-in',
                                controller: _subjectController,
                                prefixIcon: Icons.subject_rounded,
                                validator: (v) => Validators.required(v, 'Subject'),
                              ),
                              const SizedBox(height: 14),

                              AppTextField(
                                label: 'Message *',
                                hint: 'Describe your inquiry in detail...',
                                controller: _messageController,
                                maxLines: 4,
                                validator: (v) => Validators.required(v, 'Message'),
                              ),
                              const SizedBox(height: 20),

                              AppButton(
                                text: 'Submit Inquiry',
                                onPressed: _submit,
                                isLoading: contactProvider.isSubmitting,
                                icon: Icons.send_rounded,
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
    );
  }
}
