import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Retryable error state display widget
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isNetworkError = message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('socket') ||
        message.toLowerCase().contains('unavailable') ||
        message.toLowerCase().contains('offline') ||
        message.toLowerCase().contains('timeout');

    final displayTitle = isNetworkError ? 'No Internet Connection' : 'Something went wrong';
    final displayMessage = isNetworkError
        ? 'Please check your Wi-Fi or mobile data connection and try again.'
        : message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 48,
                color: isDark ? AppColors.darkError : AppColors.lightError,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayTitle,
              style: AppTypography.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: AppTypography.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: AppButton(
                  text: retryLabel,
                  onPressed: onRetry!,
                  variant: AppButtonVariant.outlined,
                  height: 42,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
