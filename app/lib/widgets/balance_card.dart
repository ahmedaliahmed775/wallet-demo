import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/wallet_model.dart';

class BalanceCard extends StatelessWidget {
  final List<WalletModel> wallets;
  final double totalBalanceYER;
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.wallets,
    this.totalBalanceYER = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الرصيد الإجمالي',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(totalBalanceYER, currency: 'YER'),
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            if (wallets.isEmpty)
              const Text(
                'لا توجد محافظ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'NotoSansArabic',
                ),
              )
            else
              Row(
                children: wallets.map((wallet) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          WalletModel.getCurrencySymbol(wallet.currency),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(wallet.balance, currency: wallet.currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansArabic',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
