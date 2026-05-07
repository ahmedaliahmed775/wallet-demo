import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../repositories/recharge_repository.dart';
import '../../models/recharge_operator_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  List<RechargeOperatorModel> _operators = [];
  String? _selectedOperatorId;
  bool _isLoading = false;
  bool _isOperatorsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    try {
      final repo = RechargeRepository();
      final result = await repo.getOperators();
      setState(() {
        _operators = result
            .map((o) => RechargeOperatorModel.fromJson(o as Map<String, dynamic>))
            .toList();
        if (_operators.isEmpty) {
          // Use default operators for demo
          _operators = [
            const RechargeOperatorModel(id: '1', nameAr: 'يمن موبايل', nameEn: 'Yemen Mobile'),
            const RechargeOperatorModel(id: '2', nameAr: 'سبافون', nameEn: 'Sabafon'),
            const RechargeOperatorModel(id: '3', nameAr: 'MTN', nameEn: 'MTN'),
            const RechargeOperatorModel(id: '4', nameAr: 'واي', nameEn: 'Y'),
          ];
        }
        _selectedOperatorId = _operators.isNotEmpty ? _operators.first.id : null;
        _isOperatorsLoading = false;
      });
    } catch (e) {
      setState(() {
        _operators = [
          const RechargeOperatorModel(id: '1', nameAr: 'يمن موبايل', nameEn: 'Yemen Mobile'),
          const RechargeOperatorModel(id: '2', nameAr: 'سبافون', nameEn: 'Sabafon'),
          const RechargeOperatorModel(id: '3', nameAr: 'MTN', nameEn: 'MTN'),
          const RechargeOperatorModel(id: '4', nameAr: 'واي', nameEn: 'Y'),
        ];
        _selectedOperatorId = _operators.first.id;
        _isOperatorsLoading = false;
      });
    }
  }

  void _showConfirmationDialog() {
    if (_selectedOperatorId == null || _phoneController.text.isEmpty || _amountController.text.isEmpty) {
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
        title: const Text('تأكيد الشحن', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ: ${CurrencyFormatter.format(amount, currency: 'YER')}', style: AppTextStyles.titleLarge),
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
                _doRecharge(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doRecharge(String confirmationCode) async {
    setState(() => _isLoading = true);
    try {
      final repo = RechargeRepository();
      final phone = '967${_phoneController.text}';
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.applyRecharge(
        operatorId: _selectedOperatorId!,
        phone: phone,
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
      appBar: AppBar(title: const Text('شحن رصيد')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر المشغل', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              _isOperatorsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _operators.isEmpty
                      ? const Text('لا يوجد مشغلين متاحين')
                      : Wrap(
                          spacing: 8,
                          children: _operators.map((op) {
                            final isSelected = _selectedOperatorId == op.id;
                            return ChoiceChip(
                              label: Text(op.nameAr),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedOperatorId = op.id),
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'رقم الهاتف',
                hint: '7XX XXX XXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefix: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Center(
                    widthFactor: 0,
                    child: Text('+967', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('المبلغ', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [500, 1000, 2000, 5000].map((amount) {
                  return ChoiceChip(
                    label: Text(CurrencyFormatter.format(amount.toDouble(), currency: 'YER')),
                    selected: _amountController.text == amount.toString(),
                    onSelected: (_) => setState(() => _amountController.text = amount.toString()),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'أو أدخل مبلغ مخصص',
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              AppButton(text: 'شحن', onPressed: _showConfirmationDialog),
            ],
          ),
        ),
      ),
    );
  }
}
