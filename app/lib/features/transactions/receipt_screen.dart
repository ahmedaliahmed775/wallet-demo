import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_party_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/receipt_card.dart';

class ReceiptScreen extends StatefulWidget {
  final String? transactionId;
  final Map<String, dynamic>? transactionData;

  const ReceiptScreen({super.key, this.transactionId, this.transactionData});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  ReceiptModel? _receipt;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.transactionData != null) {
      _receipt = _buildReceiptFromData(widget.transactionData!);
    } else if (widget.transactionId != null) {
      _fetchReceipt();
    }
  }

  Future<void> _fetchReceipt() async {
    if (widget.transactionId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = TransactionRepository();
      final result = await repo.getTransactionReceipt(transactionId: widget.transactionId!);
      final receiptData = result['receipt'] ?? result;
      setState(() {
        _receipt = _buildReceiptFromData(receiptData is Map<String, dynamic> ? receiptData : <String, dynamic>{});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  ReceiptModel _buildReceiptFromData(Map<String, dynamic> data) {
    final txn = data['transaction'] ?? data['data'] ?? data;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إيصال العملية')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إيصال العملية')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchReceipt,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final receipt = _receipt ?? ReceiptModel(
      referenceNo: '',
      type: '',
      status: 'PENDING',
      amount: 0,
      fee: 0,
      currency: 'YER',
      date: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('إيصال العملية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
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
}
