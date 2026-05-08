import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/validators.dart';
import '../../models/wallet_model.dart';
import '../../repositories/transfer_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _currency = 'YER';
  bool _isLoading = false;

  void _showConfirmationDialog() {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: AppColors.error),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ غير صحيح'), backgroundColor: AppColors.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التحويل', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إلى: 967${_phoneController.text}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'المبلغ: ${CurrencyFormatter.format(amount, currency: _currency)}',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('الرسوم: 0 ${WalletModel.getCurrencySymbol(_currency)}', style: AppTextStyles.bodySmall),
            const Divider(),
            Text('الإجمالي: ${CurrencyFormatter.format(amount, currency: _currency)}', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
            const SizedBox(height: 16),
            const Text('أدخل كود التأكيد', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('💡 كود المحاكي: 1234', style: TextStyle(color: AppColors.secondary, fontFamily: 'NotoSansArabic')),
            ),
            const SizedBox(height: 8),
            OtpInput(
              onCompleted: (code) async {
                Navigator.of(ctx).pop();
                _doTransfer(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doTransfer(String confirmationCode) async {
    setState(() => _isLoading = true);
    try {
      final repo = TransferRepository();
      final phone = '967${_phoneController.text}';
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.transfer(
        receiverPhone: phone,
        amount: amount,
        currency: _currency,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        confirmationCode: confirmationCode,
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
      appBar: AppBar(title: const Text('تحويل')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'رقم هاتف المستلم',
                hint: '7XX XXX XXX',
                controller: _phoneController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'رقم الهاتف مطلوب';
                  return null;
                },
                keyboardType: TextInputType.phone,
                prefix: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('+967', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontFamily: 'NotoSansArabic')),
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'المبلغ',
                hint: '0',
                controller: _amountController,
                validator: Validators.validateAmount,
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
                              fontFamily: 'NotoSansArabic',
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
                label: 'ملاحظة (اختياري)',
                hint: 'أضف ملاحظة',
                controller: _noteController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الرسوم', style: AppTextStyles.bodyMedium),
                    Text('0 ${WalletModel.getCurrencySymbol(_currency)}', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(text: 'تحويل', onPressed: _showConfirmationDialog),
            ],
          ),
        ),
      ),
    );
  }
}
