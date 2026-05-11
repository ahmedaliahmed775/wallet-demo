import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/bill_service_model.dart';
import '../../repositories/bills_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class PayBillScreen extends StatefulWidget {
  final BillServiceModel service;

  const PayBillScreen({super.key, required this.service});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isInquiring = false;
  Map<String, dynamic>? _billDetails;

  Future<void> _inquire() async {
    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقم الحساب'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isInquiring = true);
    try {
      final repo = BillsRepository();
      final result = await repo.inquiryBill(
        serviceCode: widget.service.serviceCode,
        accountNumber: _accountController.text,
      );
      setState(() => _isInquiring = false);
      final data = result['data'] ?? result;
      if (data['billDetails'] != null) {
        setState(() {
          _billDetails = data['billDetails'] as Map<String, dynamic>;
          _amountController.text = (_billDetails!['amountDue'] as num?)?.toString() ?? '';
        });
      } else if (result['success'] == true || data['amountDue'] != null) {
        setState(() {
          _billDetails = (data is Map<String, dynamic>) ? data : {};
          _amountController.text = (data['amountDue'] as num?)?.toString() ?? '';
        });
      }
    } catch (e) {
      setState(() => _isInquiring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    }
  }

  void _showConfirmationDialog() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الدفع', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.service.nameAr, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text('المبلغ: ${CurrencyFormatter.format(amount, currency: 'YER')}', style: AppTextStyles.titleLarge),
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
                _payBill(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payBill(String confirmationCode) async {
    setState(() => _isLoading = true);
    try {
      final repo = BillsRepository();
      final amount = double.tryParse(_amountController.text) ?? 0;
      final result = await repo.payBill(
        serviceCode: widget.service.serviceCode,
        accountNumber: _accountController.text,
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
      appBar: AppBar(title: Text(widget.service.nameAr)),
      body: LoadingOverlay(
        isLoading: _isLoading || _isInquiring,
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
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.service.nameAr, style: AppTextStyles.titleLarge),
                          if (widget.service.category != null)
                            Text(widget.service.category!, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'رقم الحساب / المشترك',
                hint: 'أدخل رقم الحساب',
                controller: _accountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'استعلام',
                onPressed: _inquire,
                isOutlined: true,
              ),
              if (_billDetails != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('اسم المشترك', _billDetails!['accountHolder']?.toString() ?? ''),
                      _buildDetailRow('المبلغ المستحق', '${_billDetails!['amountDue'] ?? '0'} ر.ي'),
                      _buildDetailRow('تاريخ الاستحقاق', _billDetails!['dueDate']?.toString() ?? ''),
                      _buildDetailRow('رقم الفاتورة', _billDetails!['billNumber']?.toString() ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'المبلغ',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                AppButton(text: 'سداد', onPressed: _showConfirmationDialog),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
