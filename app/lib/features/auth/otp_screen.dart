import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String purpose;
  final VoidCallback? onVerified;

  const OtpScreen({
    super.key,
    required this.phone,
    this.purpose = 'LOGIN',
    this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int _resendTimer = 45;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 45;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendTimer--;
      });
      if (_resendTimer <= 0) {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  void _resendOtp() {
    if (_canResend) {
      context.read<AuthBloc>().add(AuthOtpRequested(
            phone: widget.phone,
            shortCode: '1234',
            purpose: widget.purpose,
          ));
      _startTimer();
    }
  }

  /// Mask the phone number for display.
  String _maskPhone(String phone) {
    if (phone.length >= 7) {
      return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الرمز'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpVerified || state is AuthAuthenticated) {
            widget.onVerified?.call();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthLoading,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.sms,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'أدخل رمز التحقق',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تم الإرسال إلى ${_maskPhone(widget.phone)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  OtpInput(
                    onCompleted: (code) {
                      context.read<AuthBloc>().add(AuthOtpVerifyRequested(
                            phone: widget.phone,
                            code: code,
                            purpose: widget.purpose,
                          ));
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '💡 رمز المحاكي: 1234',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _canResend
                      ? TextButton(
                          onPressed: _resendOtp,
                          child: const Text('إعادة إرسال الرمز'),
                        )
                      : Text(
                          'إعادة الإرسال بعد $_resendTimer ثانية',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
