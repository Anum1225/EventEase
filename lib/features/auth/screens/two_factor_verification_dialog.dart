import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

class TwoFactorVerificationDialog extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final Future<String> Function() onResendOtp;

  const TwoFactorVerificationDialog({
    super.key,
    required this.email,
    required this.generatedOtp,
    required this.onResendOtp,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String email,
    required String generatedOtp,
    required Future<String> Function() onResendOtp,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: TwoFactorVerificationDialog(
          email: email,
          generatedOtp: generatedOtp,
          onResendOtp: onResendOtp,
        ),
      ),
    );
  }

  @override
  State<TwoFactorVerificationDialog> createState() => _TwoFactorVerificationDialogState();
}

class _TwoFactorVerificationDialogState extends State<TwoFactorVerificationDialog> {
  late String _currentOtp;
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _countdownTimer;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.generatedOtp;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _fillCode(String code) {
    if (code.length != 6) return;
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = code[i];
    }
    _verify();
  }

  String _getEnteredCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _verify() {
    final entered = _getEnteredCode().trim();
    if (entered.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    if (entered == _currentOtp) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = 'Invalid 2FA code. Please try again.';
      });
      // Clear fields on error
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final newOtp = await widget.onResendOtp();
      setState(() {
        _currentOtp = newOtp;
        _isResending = false;
      });
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New 2FA code dispatched!')),
        );
      }
    } catch (e) {
      setState(() {
        _isResending = false;
        _errorMessage = 'Failed to resend code: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shield Icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 32,
                  color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Two-Factor Authorization',
              textAlign: TextAlign.center,
              style: AppTypography.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'Enter the 6-digit security code sent to\n${widget.email}',
              textAlign: TextAlign.center,
              style: AppTypography.manrope(
                fontSize: 13,
                height: 1.4,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 18),

            // Demo / Test OTP Quick Paste Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Security Code: $_currentOtp',
                      style: AppTypography.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      _fillCode(_currentOtp);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code auto-filled & verified!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Auto Fill',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6-Digit Pin Input Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1B1E2B) : const Color(0xFFF3EFE6),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          _focusNodes[index].unfocus();
                          _verify();
                        }
                      } else if (index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.lightError,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Resend Code Timer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: AppTypography.manrope(
                    fontSize: 12.5,
                    color: secondaryTextColor,
                  ),
                ),
                InkWell(
                  onTap: _resendCountdown == 0 ? _resendCode : null,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend in ${_resendCountdown}s'
                        : (_isResending ? 'Sending...' : 'Resend Code'),
                    style: AppTypography.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _resendCountdown == 0
                          ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                          : secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            AppButton(
              text: 'Verify & Authorize',
              icon: Icons.lock_open_rounded,
              variant: AppButtonVariant.organizer,
              onPressed: _verify,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
