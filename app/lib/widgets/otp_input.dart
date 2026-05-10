import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class OtpInput extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;

  const OtpInput({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.removeListener(() => setState(() {}));
      node.dispose();
    }
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _checkComplete();
  }

  void _onFieldSubmitted(String value, int index) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _checkComplete();
    }
  }

  void _checkComplete() {
    final code = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (index) {
          final hasFocus = _focusNodes[index].hasFocus;
          return Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: hasFocus ? AppColors.surface : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFocus ? AppColors.primary : AppColors.divider,
                width: hasFocus ? 2 : 1.5,
              ),
            ),
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLength: 1,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _onChanged(value, index),
              onFieldSubmitted: (value) => _onFieldSubmitted(value, index),
            ),
          );
        }),
      ),
    );
  }
}
