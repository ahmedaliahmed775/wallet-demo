import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _internalFocusNode;
  bool _hasFocus = false;
  String? _errorText;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _effectiveFocusNode.hasFocus;
      });
    }
  }

  Color _getBorderColor() {
    if (_errorText != null) return AppColors.error;
    if (_hasFocus) return AppColors.primary;
    return const Color(0xFF9CA3AF);
  }

  double _getBorderWidth() {
    if (_errorText != null || _hasFocus) return 2.0;
    return 1.5;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNumeric = widget.isNumberField ||
        widget.keyboardType == TextInputType.number ||
        widget.keyboardType == TextInputType.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _getBorderColor(),
              width: _getBorderWidth(),
            ),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            validator: (value) {
              final error = widget.validator?.call(value);
              // تأجيل تحديث الحالة لتجنب التعارض مع دورة البناء (Build Cycle)
              if (_errorText != error) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _errorText = error;
                    });
                  }
                });
              }
              return error;
            },
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            textInputAction: widget.textInputAction,
            focusNode: _effectiveFocusNode,
            style: TextStyle(
              color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'NotoSansArabic',
            ),
            textAlign: isNumeric ? TextAlign.left : TextAlign.right,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: AppColors.primary,
            textDirection: isNumeric ? TextDirection.ltr : null,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
                fontFamily: 'NotoSansArabic',
              ),
              counterText: '',
              prefixIcon: widget.prefix != null
                  ? Padding(
                      // استخدام EdgeInsets بدلاً من EdgeInsetsDirectional لتفادي تعارض LTR/RTL
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: widget.prefix,
                    )
                  : null,
              suffixIcon: widget.suffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              // استخدام لون شفاف وحجم خط دقيق جداً لمنع انهيار التخطيط
              errorStyle: const TextStyle(fontSize: 0.01, color: Colors.transparent),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontFamily: 'NotoSansArabic',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }
}
