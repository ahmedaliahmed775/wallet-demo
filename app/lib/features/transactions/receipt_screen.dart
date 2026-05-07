import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_party_model.dart';
import '../../widgets/receipt_card.dart';
import 'package:flutter/services.dart';

class ReceiptScreen extends StatelessWidget {
  final String? transactionId;
  final Map<String, dynamic>? transactionData;

  const ReceiptScreen({super.key, this.transactionId, this.transactionData});

  @override
  Widget build(BuildContext context) {
    final receipt = _buildReceipt();

    return Scaffold(
      appBar: AppBar(title: const Text('إيصال العملية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Success animation - green checkmark icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              receipt.status == 'COMPLETED' ? 'تمت بنجاح' : receipt.statusAr,
              style: AppTextStyles.headlineMedium.copyWith(
                color: receipt.status == 'COMPLETED' ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            ReceiptCard(
              receipt: receipt,
              onCopy: () {
                Clipboard.setData(ClipboardData(
                  text: 'المرجع: ${receipt.referenceNo}\nالمبلغ: ${CurrencyFormatter.format(receipt.amount, currency: receipt.currency)}\nالتاريخ: ${DateFormatter.formatDateTime(receipt.date)}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ')),
                );
              },
              onShare: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المشاركة قريباً')),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('العودة للرئيسية', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ReceiptModel _buildReceipt() {
    if (transactionData != null) {
      final txn = transactionData!['transaction'] ?? transactionData!['data'] ?? transactionData!;
      return ReceiptModel(
        referenceNo: txn['referenceNo']?.toString() ?? '',
        type: txn['type']?.toString() ?? '',
        status: txn['status']?.toString() ?? 'COMPLETED',
        amount: (txn['amount'] as num?)?.toDouble() ?? 0,
        fee: (txn['fee'] as num?)?.toDouble() ?? 0,
        netAmount: txn['netAmount'] != null ? (txn['netAmount'] as num).toDouble() : null,
        currency: txn['currency']?.toString() ?? 'YER',
        description: txn['description']?.toString(),
        notes: txn['notes']?.toString(),
        posNumber: txn['posNumber']?.toString(),
        date: txn['createdAt'] != null ? DateTime.tryParse(txn['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
        sender: txn['sender'] != null
            ? TransactionParty(
                name: txn['sender']['name']?.toString(),
                phone: txn['sender']['phone']?.toString(),
              )
            : (txn['senderName'] != null
                ? TransactionParty(name: txn['senderName']?.toString(), phone: txn['senderPhone']?.toString())
                : null),
        receiver: txn['receiver'] != null
            ? TransactionParty(
                name: txn['receiver']['name']?.toString(),
                phone: txn['receiver']['phone']?.toString(),
              )
            : (txn['receiverName'] != null
                ? TransactionParty(name: txn['receiverName']?.toString(), phone: txn['receiverPhone']?.toString())
                : null),
      );
    }
    return ReceiptModel(
      referenceNo: '',
      type: '',
      status: 'PENDING',
      amount: 0,
      fee: 0,
      currency: 'YER',
      date: DateTime.now(),
    );
  }
}
