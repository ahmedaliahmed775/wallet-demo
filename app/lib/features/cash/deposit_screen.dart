import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/storage/secure_storage.dart';
import '../../models/wallet_model.dart';
import '../../repositories/cash_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _agentWalletController = TextEditingController();
  String _currency = 'YER';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFillPhone();
  }

  Future<void> _autoFillPhone() async {
    final phone = await SecureStorage.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final local = phone.startsWith('967') ? phone.substring(3) : phone;
      _phoneController.text = local;
    }
  }

  Future<void> _deposit() async {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty || _agentWalletController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = CashRepository();
      final phone = '967${_phoneController.text}';
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.deposit(
        agentWallet: _agentWalletController.text,
        amount: amount,
        currency: _currency,
        receiverPhone: phone,
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
      appBar: AppBar(title: const Text('إيداع نقدي')),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'الإيداع يتم عن طريق وكيل. أدخل رقم محفظة الوكيل ورقم هاتف المستلم.',
                        style: TextStyle(
                          color: AppColors.primary,
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
                label: 'رقم هاتف المستلم',
                hint: '7XX XXX XXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefix: const Icon(Icons.phone_android, color: AppColors.textSecondary, size: 22),
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
              const SizedBox(height: 32),
              AppButton(text: 'إيداع', onPressed: _deposit),
            ],
          ),
        ),
      ),
    );
  }
}
