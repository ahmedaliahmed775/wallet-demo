import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/otp_input.dart';
import '../../repositories/payment_repository.dart';
import '../../widgets/loading_overlay.dart';
import '../transactions/receipt_screen.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const ConfirmPaymentScreen({super.key, required this.paymentData});

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  bool _isLoading = false;

  Future<void> _confirmPayment(String confirmationCode) async {
    setState(() => _isLoading = true);
    try {
      final repo = PaymentRepository();
      final result = await repo.confirmPayment(
        transactionId: widget.paymentData['transactionId'] ?? '',
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
    final amount = widget.paymentData['amount'] ?? 0;
    final currency = widget.paymentData['currency'] ?? 'YER';
    final referenceNo = widget.paymentData['referenceNo'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الدفع')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('تفاصيل العملية', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 16),
                    _buildDetailRow('المبلغ', CurrencyFormatter.format((amount as num).toDouble(), currency: currency)),
                    _buildDetailRow('رقم المرجع', referenceNo.toString()),
                    if (widget.paymentData['merchant'] != null)
                      _buildDetailRow('التاجر', widget.paymentData['merchant']['businessName'] ?? ''),
                    if (widget.paymentData['description'] != null)
                      _buildDetailRow('الوصف', widget.paymentData['description'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('أدخل كود التأكيد', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              OtpInput(
                onCompleted: _confirmPayment,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.secondary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 كود المحاكي: 1234',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'إلغاء',
                      isOutlined: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
