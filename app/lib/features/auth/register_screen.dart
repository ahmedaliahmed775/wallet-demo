import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();

  // Step 2
  final _phoneController = TextEditingController();
  String _gender = 'MALE';

  // Step 3
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  String get _fullName =>
      '${_firstNameController.text} ${_fatherNameController.text} ${_grandfatherNameController.text} ${_familyNameController.text}';

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _familyNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _firstNameController.text.isNotEmpty &&
            _fatherNameController.text.isNotEmpty &&
            _grandfatherNameController.text.isNotEmpty &&
            _familyNameController.text.isNotEmpty;
      case 1:
        return _phoneController.text.length >= 9;
      case 2:
        return _passwordController.text.length >= 6 &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateStep()) {
      if (_currentStep < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _register();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول بشكل صحيح'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _register() {
    final phone = '967${_phoneController.text}';
    context.read<AuthBloc>().add(AuthRegisterRequested(
          name: _fullName,
          phone: phone,
          password: _passwordController.text,
          gender: _gender,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  phone: state.phone,
                  purpose: 'REGISTER',
                  onVerified: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ),
            );
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: AppButton(
                            text: 'رجوع',
                            isOutlined: true,
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() => _currentStep--);
                            },
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: _currentStep == 2 ? 'إنشاء حساب' : 'التالي',
                          onPressed: _nextStep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الاسم الكامل', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          const Text('أدخل أجزاء اسمك الأربعة', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          AppTextField(
            label: 'الاسم الأول',
            hint: 'محمد',
            controller: _firstNameController,
            validator: (v) => Validators.validateName(v, 'الاسم الأول'),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'اسم الأب',
            hint: 'أحمد',
            controller: _fatherNameController,
            validator: (v) => Validators.validateName(v, 'اسم الأب'),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'اسم الجد',
            hint: 'علي',
            controller: _grandfatherNameController,
            validator: (v) => Validators.validateName(v, 'اسم الجد'),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'اسم العائلة',
            hint: 'الحسني',
            controller: _familyNameController,
            validator: (v) => Validators.validateName(v, 'اسم العائلة'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('معلومات الاتصال', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          const Text('أدخل رقم هاتفك والجنس', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
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
            prefix: const Icon(Icons.phone_android, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 24),
          const Text('الجنس', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'MALE'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gender == 'MALE'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _gender == 'MALE'
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: const Center(
                      child: Text('ذكر', style: AppTextStyles.titleMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'FEMALE'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gender == 'FEMALE'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _gender == 'FEMALE'
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: const Center(
                      child: Text('أنثى', style: AppTextStyles.titleMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('كلمة المرور', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          const Text('أنشئ كلمة مرور لحسابك', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          AppTextField(
            label: 'تأكيد كلمة المرور',
            hint: 'أعد إدخال كلمة المرور',
            controller: _confirmPasswordController,
            validator: (v) {
              if (v != _passwordController.text) {
                return 'كلمتا المرور غير متطابقتين';
              }
              return null;
            },
            obscureText: _obscurePassword,
          ),
        ],
      ),
    );
  }
}
