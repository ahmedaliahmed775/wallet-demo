import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/transaction/transaction_event.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/transaction_item.dart';
import '../payment/scan_qr_screen.dart';
import '../payment/generate_code_screen.dart';
import '../transactions/history_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletBalanceRequested());
    context.read<TransactionBloc>().add(const TransactionHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomePage(user),
              _buildPaymentPage(),
              const HistoryScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.store),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment),
                label: 'دفع',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'سجل',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'حسابي',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomePage(user) {
    final businessName = user?.merchant?.businessName ?? 'نقطة المبيعات';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WalletBloc>().add(WalletBalanceRequested());
          context.read<TransactionBloc>().add(const TransactionHistoryRequested());
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 60,
              floating: true,
              backgroundColor: AppColors.primary,
              title: Text(
                businessName,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BlocBuilder<WalletBloc, WalletState>(
                      builder: (context, state) {
                        if (state is WalletLoaded) {
                          return BalanceCard(
                            wallets: state.wallets,
                            totalBalanceYER: state.totalInYER,
                          );
                        }
                        return const BalanceCard(wallets: [], totalBalanceYER: 0);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Stats card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('اليوم', style: AppTextStyles.titleLarge),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem('العمليات', '0', Icons.receipt),
                              ),
                              Expanded(
                                child: _buildStatItem('المبلغ', '0 ر.ي', Icons.attach_money),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('الإجراءات السريعة', style: AppTextStyles.headlineSmall),
                    ),
                    const SizedBox(height: 12),
                    // 2x3 grid of action buttons
                    Row(
                      children: [
                        _buildActionItem('📷', 'مسح QR Code', () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ScanQrScreen()),
                          );
                        }),
                        _buildActionItem('🔢', 'طلب دفع بالرقم', () {
                          setState(() => _currentIndex = 1);
                        }),
                        _buildActionItem('📱', 'توليد كود دفع', () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GenerateCodeScreen()),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionItem('🔄', 'استرجاع عملية', () {}),
                        _buildActionItem('📋', 'سجل العمليات', () {
                          setState(() => _currentIndex = 2);
                        }),
                        _buildActionItem('📊', 'التقارير', () {}),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('آخر العمليات', style: AppTextStyles.headlineSmall),
                        TextButton(
                          onPressed: () => setState(() => _currentIndex = 2),
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<TransactionBloc, TransactionState>(
                      builder: (context, state) {
                        if (state is TransactionLoaded) {
                          final recent = state.transactions.take(3).toList();
                          if (recent.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Icon(Icons.receipt_long, size: 48, color: AppColors.textHint),
                                  const SizedBox(height: 8),
                                  Text(
                                    'لا توجد عمليات بعد',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: recent.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionItem(transaction: t),
                            )).toList(),
                          );
                        }
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ));
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        )),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        )),
      ],
    );
  }

  Widget _buildActionItem(String emoji, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('الدفع')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPaymentOption('📷 مسح QR Code', 'امسح رمز QR للعميل', Icons.qr_code_scanner, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanQrScreen()));
            }),
            const SizedBox(height: 12),
            _buildPaymentOption('📱 توليد كود دفع', 'أنشئ رمز QR للدفع', Icons.qr_code, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GenerateCodeScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
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
              color: Colors.black.withOpacity(0.05),
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
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
