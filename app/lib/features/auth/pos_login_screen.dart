import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../home/merchant_home_screen.dart';

class PosLoginScreen extends StatefulWidget {
  const PosLoginScreen({super.key});

  @override
  State<PosLoginScreen> createState() => _PosLoginScreenState();
}

class _PosLoginScreenState extends State<PosLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _shortCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    if (_formKey.currentState!.validate()) {
      final phone = '967${_phoneController.text}';
      context.read<AuthBloc>().add(PosLoginRequested(
            phone: phone,
            shortCode: _shortCodeController.text,
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.role == 'MERCHANT' || state.user.role == 'POS') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MerchantHomeScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('هذا الحساب ليس نقطة بيع'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '🏪',
                            style: TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '🏪 دخول كنقطة مبيعات',
                        style: AppTextStyles.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'رقم الهاتف',
                      hint: '7XX XXX XXX',
                      controller: _phoneController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'رقم الهاتف مطلوب';
                        if (v.length < 9) return 'رقم الهاتف غير صحيح';
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                      prefix: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Center(
                          widthFactor: 0,
                          child: Text(
                            '+967',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'الرمز المختصر',
                      hint: '6 أرقام',
                      controller: _shortCodeController,
                      validator: Validators.validateShortCode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'كلمة المرور',
                      hint: 'أدخل كلمة المرور',
                      controller: _passwordController,
                      validator: Validators.validatePassword,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: 'طلب رمز OTP',
                      onPressed: _requestOtp,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
