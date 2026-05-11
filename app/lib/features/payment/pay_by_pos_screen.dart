import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/wallet_model.dart';
import '../../repositories/payment_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class PayByPosScreen extends StatefulWidget {
  const PayByPosScreen({super.key});

  @override
  State<PayByPosScreen> createState() => _PayByPosScreenState();
}

class _PayByPosScreenState extends State<PayByPosScreen> {
  final _posNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _currency = 'YER';
  bool _isLoading = false;

  void _showConfirmationDialog() {
    if (_posNumberController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: AppColors.error),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الدفع', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رقم نقطة البيع: ${_posNumberController.text}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'المبلغ: ${CurrencyFormatter.format(amount, currency: _currency)}',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('أدخل كود التأكيد', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('💡 كود المحاكي: 1234', style: TextStyle(color: AppColors.secondary, fontFamily: 'NotoSansArabic')),
            ),
            const SizedBox(height: 8),
            OtpInput(
              onCompleted: (code) async {
                Navigator.of(ctx).pop();
                _doPayment(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doPayment(String confirmationCode) async {
    setState(() => _isLoading = true);
    try {
      final repo = PaymentRepository();
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.payByPos(
        posNumber: _posNumberController.text,
        amount: amount,
        confirmationCode: confirmationCode,
        currency: _currency,
      );
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(transactionData: result),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدفع بنقطة البيع')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'رقم نقطة البيع',
                hint: 'أدخل الرمز المختصر أو رقم الجهاز',
                controller: _posNumberController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'المبلغ',
                hint: '0',
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: ['YER', 'USD', 'SAR'].map((c) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currency = c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currency == c ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currency == c ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            WalletModel.getCurrencySymbol(c),
                            style: TextStyle(
                              color: _currency == c ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'الوصف (اختياري)',
                hint: 'وصف العملية',
                controller: _descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              AppButton(text: 'دفع', onPressed: _showConfirmationDialog),
            ],
          ),
        ),
      ),
    );
  }
}
