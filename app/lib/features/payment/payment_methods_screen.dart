import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'scan_qr_screen.dart';
import 'pay_by_pos_screen.dart';
import 'generate_code_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _hideIdentity = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طرق الدفع')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPaymentCard(
              icon: Icons.qr_code_scanner,
              title: '📷 مسح QR Code',
              subtitle: 'امسح رمز QR لدفع المبلغ',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScanQrScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentCard(
              icon: Icons.store,
              title: '🔢 رقم نقطة البيع',
              subtitle: 'ادفع باستخدام رقم نقطة البيع',
              color: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PayByPosScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentCard(
              icon: Icons.qr_code,
              title: '📱 توليد كود دفع',
              subtitle: 'أنشئ رمز دفع لمسح التاجر',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GenerateCodeScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: SwitchListTile(
                value: _hideIdentity,
                onChanged: (v) => setState(() => _hideIdentity = v),
                title: const Text('🔒 إخفاء اسمي ورقمي عند الدفع', style: AppTextStyles.titleMedium),
                subtitle: const Text('لن يرى المستلم اسمك ورقمك', style: AppTextStyles.bodySmall),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
