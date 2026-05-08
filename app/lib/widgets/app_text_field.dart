import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool isNumberField;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.isNumberField = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this is a number-type field
    final bool isNumeric = isNumberField ||
        keyboardType == TextInputType.number ||
        keyboardType == TextInputType.phone ||
        keyboardType == TextInputType.numberWithOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          const SizedBox(height: 6),
        ],
        // Wrap number fields in LTR directionality to fix RTL issues
        Directionality(
          textDirection: isNumeric ? TextDirection.ltr : TextDirection.rtl,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            maxLength: maxLength,
            enabled: enabled,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            textInputAction: textInputAction,
            focusNode: focusNode,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'NotoSansArabic',
            ),
            textAlign: isNumeric ? TextAlign.left : TextAlign.right,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
                fontFamily: 'NotoSansArabic',
              ),
              counterText: '',
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              // Make borders VERY visible
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF9CA3AF), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF9CA3AF), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.error, width: 2.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
