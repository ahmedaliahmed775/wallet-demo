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
import '../../widgets/service_grid.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/app_text_field.dart';
import '../transfer/transfer_screen.dart';
import '../transfer/between_accounts_screen.dart';
import '../payment/payment_methods_screen.dart';
import '../recharge/recharge_screen.dart';
import '../bills/bills_screen.dart';
import '../cash/withdraw_screen.dart';
import '../transactions/history_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
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
              _buildServicesPage(),
              const HistoryScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.apps),
                label: 'خدمات',
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
                'مرحباً، ${user?.name ?? 'عميل'} 👋',
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
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    setState(() => _currentIndex = 3);
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
                    if (user != null && !user.isVerified) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showKycDialog(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: AppColors.warning),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '⚠️ اضغط هنا لتأكيد محفظتك',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('الخدمات', style: AppTextStyles.headlineSmall),
                    ),
                    const SizedBox(height: 12),
                    ServiceGrid(
                      services: const [
                        ServiceItem(label: '💸 تحويل', icon: Icons.swap_horiz, color: Colors.blue),
                        ServiceItem(label: '📱 شحن رصيد', icon: Icons.phone_android, color: Colors.orange),
                        ServiceItem(label: '🧾 سداد خدمات', icon: Icons.receipt_long, color: Colors.purple),
                        ServiceItem(label: '🛒 دفع مشتريات', icon: Icons.payment, color: AppColors.primary),
                        ServiceItem(label: '💵 سحب/إيداع', icon: Icons.money, color: Colors.teal),
                        ServiceItem(label: '🔄 بين حساباتي', icon: Icons.currency_exchange, color: Colors.indigo),
                      ],
                      onItemTap: (index) => _onServiceTap(index),
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
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        );
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

  Widget _buildServicesPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('الخدمات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ServiceGrid(
          services: const [
            ServiceItem(label: '💸 تحويل', icon: Icons.swap_horiz, color: Colors.blue),
            ServiceItem(label: '📱 شحن رصيد', icon: Icons.phone_android, color: Colors.orange),
            ServiceItem(label: '🧾 سداد خدمات', icon: Icons.receipt_long, color: Colors.purple),
            ServiceItem(label: '🛒 دفع مشتريات', icon: Icons.payment, color: AppColors.primary),
            ServiceItem(label: '💵 سحب/إيداع', icon: Icons.money, color: Colors.teal),
            ServiceItem(label: '🔄 بين حساباتي', icon: Icons.currency_exchange, color: Colors.indigo),
          ],
          onItemTap: (index) => _onServiceTap(index),
        ),
      ),
    );
  }

  void _onServiceTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransferScreen()));
        break;
      case 1:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RechargeScreen()));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BillsScreen()));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WithdrawScreen()));
        break;
      case 5:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetweenAccountsScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الخدمة قريباً')),
        );
    }
  }

  void _showKycDialog(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final fatherNameCtrl = TextEditingController();
    final grandfatherNameCtrl = TextEditingController();
    final familyNameCtrl = TextEditingController();
    final nationalIdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الهوية', style: AppTextStyles.headlineSmall),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'رقم الهوية',
                  controller: nationalIdCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'الاسم',
                  controller: firstNameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'اسم الأب',
                  controller: fatherNameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'اسم الجد',
                  controller: grandfatherNameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'اسم العائلة',
                  controller: familyNameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop();
                context.read<AuthBloc>().add(AuthKycRequested(
                      nationalId: nationalIdCtrl.text,
                      firstName: firstNameCtrl.text,
                      fatherName: fatherNameCtrl.text,
                      grandfatherName: grandfatherNameCtrl.text,
                      familyName: familyNameCtrl.text,
                    ));
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
