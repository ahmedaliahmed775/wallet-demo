import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/wallet_model.dart';
import '../../repositories/transfer_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class BetweenAccountsScreen extends StatefulWidget {
  const BetweenAccountsScreen({super.key});

  @override
  State<BetweenAccountsScreen> createState() => _BetweenAccountsScreenState();
}

class _BetweenAccountsScreenState extends State<BetweenAccountsScreen> {
  final _amountController = TextEditingController();
  String _fromCurrency = 'YER';
  String _toCurrency = 'USD';
  bool _isLoading = false;

  double get _convertedAmount {
    return CurrencyFormatter.convert(
      double.tryParse(_amountController.text) ?? 0,
      _fromCurrency,
      _toCurrency,
    );
  }

  String get _exchangeRateText {
    if (_fromCurrency == _toCurrency) return '1:1';
    if (_fromCurrency == 'YER' && _toCurrency == 'USD') return '1 USD = 530 ر.ي';
    if (_fromCurrency == 'YER' && _toCurrency == 'SAR') return '1 SAR = 141 ر.ي';
    if (_fromCurrency == 'USD' && _toCurrency == 'YER') return '1 USD = 530 ر.ي';
    if (_fromCurrency == 'SAR' && _toCurrency == 'YER') return '1 SAR = 141 ر.ي';
    if (_fromCurrency == 'USD' && _toCurrency == 'SAR') return '1 USD ≈ 3.75 SAR';
    if (_fromCurrency == 'SAR' && _toCurrency == 'USD') return '1 SAR ≈ 0.27 USD';
    return '';
  }

  void _showConfirmationDialog() {
    if (_amountController.text.isEmpty) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التحويل', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${CurrencyFormatter.format(amount, currency: _fromCurrency)} ← ${CurrencyFormatter.format(_convertedAmount, currency: _toCurrency)}',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
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
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.transferBetweenAccounts(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amount,
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
      appBar: AppBar(title: const Text('تحويل بين حساباتي')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('من حساب', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: ['YER', 'USD', 'SAR'].map((c) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _fromCurrency = c;
                          if (_toCurrency == c) {
                            _toCurrency = c == 'YER' ? 'USD' : 'YER';
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _fromCurrency == c ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _fromCurrency == c ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${WalletModel.getCurrencySymbol(c)} ${WalletModel.getCurrencyNameAr(c)}',
                            style: TextStyle(
                              color: _fromCurrency == c ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoSansArabic',
                              fontSize: 12,
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
                label: 'المبلغ',
                hint: '0',
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Center(child: Icon(Icons.swap_vert, size: 36, color: AppColors.primary)),
              const SizedBox(height: 20),
              const Text('إلى حساب', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: ['YER', 'USD', 'SAR'].where((c) => c != _fromCurrency).map((c) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _toCurrency = c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _toCurrency == c ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _toCurrency == c ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${WalletModel.getCurrencySymbol(c)} ${WalletModel.getCurrencyNameAr(c)}',
                            style: TextStyle(
                              color: _toCurrency == c ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoSansArabic',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('سعر الصرف: $_exchangeRateText', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null && double.tryParse(_amountController.text)! > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ستحصل على', style: AppTextStyles.bodyMedium),
                      Text(
                        CurrencyFormatter.format(_convertedAmount, currency: _toCurrency),
                        style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                      ),
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
