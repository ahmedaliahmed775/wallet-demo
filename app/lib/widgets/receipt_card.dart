import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../models/receipt_model.dart';

class ReceiptCard extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            receipt.typeAr,
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(receipt.amount, currency: receipt.currency),
            style: AppTextStyles.amount(fontSize: 28, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          _buildRow('رقم المرجع', receipt.referenceNo),
          _buildRow('الحالة', receipt.status == 'COMPLETED' ? 'مكتمل' : receipt.statusAr),
          _buildRow('التاريخ', DateFormatter.formatDateTime(receipt.date)),
          if (receipt.fee > 0)
            _buildRow('الرسوم', CurrencyFormatter.format(receipt.fee, currency: receipt.currency)),
          if (receipt.netAmount != null && receipt.netAmount != receipt.amount)
            _buildRow('المبلغ الصافي', CurrencyFormatter.format(receipt.netAmount!, currency: receipt.currency)),
          if (receipt.sender != null && receipt.sender!.name != null)
            _buildRow('المرسل', receipt.sender!.name!),
          if (receipt.receiver != null && receipt.receiver!.name != null)
            _buildRow('المستلم', receipt.receiver!.name!),
          if (receipt.posNumber != null)
            _buildRow('رقم نقطة البيع', receipt.posNumber!),
          if (receipt.description != null)
            _buildRow('الوصف', receipt.description!),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('نسخ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('مشاركة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
