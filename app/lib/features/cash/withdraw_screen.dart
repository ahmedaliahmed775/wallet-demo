import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/wallet_model.dart';
import '../../repositories/cash_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _agentWalletController = TextEditingController();
  String _currency = 'YER';
  bool _isLoading = false;

  void _showConfirmationDialog() {
    if (_amountController.text.isEmpty || _agentWalletController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: AppColors.error),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final fee = amount * 0.02;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد السحب', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ: ${CurrencyFormatter.format(amount, currency: _currency)}', style: AppTextStyles.titleLarge),
            Text('الرسوم (2%): ${CurrencyFormatter.format(fee, currency: _currency)}', style: AppTextStyles.bodyMedium),
            const Divider(),
            Text('ستستلم: ${CurrencyFormatter.format(amount - fee, currency: _currency)}', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
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
                _doWithdraw(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doWithdraw(String confirmationCode) async {
    setState(() => _isLoading = true);
    try {
      final repo = CashRepository();
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.withdraw(
        agentWallet: _agentWalletController.text,
        amount: amount,
        currency: _currency,
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
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = amount * 0.02;

    return Scaffold(
      appBar: AppBar(title: const Text('سحب نقدي')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'السحب يتم عبر وكيل. رسوم السحب 2%.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'رقم محفظة الوكيل',
                hint: 'MFxxxxxxxx',
                controller: _agentWalletController,
                keyboardType: TextInputType.text,
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
              if (amount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرسوم (2%)', style: AppTextStyles.bodyMedium),
                          Text(
                            CurrencyFormatter.format(fee, currency: _currency),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ستستلم', style: AppTextStyles.titleMedium),
                          Text(
                            CurrencyFormatter.format(amount - fee, currency: _currency),
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(text: 'سحب', onPressed: _showConfirmationDialog),
            ],
          ),
        ),
      ),
    );
  }
}
