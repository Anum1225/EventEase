import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Form text field with unified styling, error presentation, and password toggle
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.enabled = true,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Widget? suffixIcon = widget.suffix;
    if (widget.isPassword) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: secondaryTextColor,
        ),
        onPressed: () {
          setState(() {
            _obscured = !_obscured;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          textCapitalization: widget.textCapitalization,
          style: AppTypography.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: secondaryTextColor)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
