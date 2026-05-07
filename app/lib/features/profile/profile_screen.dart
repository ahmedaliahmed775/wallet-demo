import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../models/wallet_model.dart';
import '../../repositories/auth_repository.dart';
import '../role_selection/role_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _hideIdentity = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = authState.user;

          return BlocBuilder<WalletBloc, WalletState>(
            builder: (context, walletState) {
              final wallets = walletState is WalletLoaded ? walletState.wallets : <WalletModel>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'NotoSansArabic',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(user.name, style: AppTextStyles.headlineSmall),
                          const SizedBox(height: 4),
                          Text(user.phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isVerified ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isVerified ? Icons.verified : Icons.warning,
                                  size: 16,
                                  color: user.isVerified ? AppColors.success : AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isVerified ? '✅ حساب مفعّل' : '⚠️ حساب غير مفعّل',
                                  style: TextStyle(
                                    color: user.isVerified ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Wallets list
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('محافظي', style: AppTextStyles.titleLarge),
                          const SizedBox(height: 12),
                          ...wallets.map((wallet) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                WalletModel.getCurrencySymbol(wallet.currency),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            WalletModel.getCurrencyNameAr(wallet.currency),
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        CurrencyFormatter.format(wallet.balance, currency: wallet.currency),
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuSection([
                      _MenuItem(Icons.lock, '🔢 تغيير كلمة المرور', () {
                        _showChangePasswordDialog();
                      }),
                      _MenuItem(Icons.pin, '🔐 تغيير كود التأكيد', () {
                        _showChangeConfirmationCodeDialog();
                      }),
                      _MenuItem(Icons.visibility_off, '🔒 إخفاء الهوية عند الدفع', () {
                        setState(() => _hideIdentity = !_hideIdentity);
                      }, trailing: Switch(
                        value: _hideIdentity,
                        onChanged: (v) => setState(() => _hideIdentity = v),
                        activeColor: AppColors.primary,
                      )),
                      _MenuItem(Icons.language, '🌐 اللغة', () {}),
                      _MenuItem(Icons.notifications, '🔔 الإشعارات', () {}),
                    ]),
                    const SizedBox(height: 16),
                    _buildMenuSection([
                      _MenuItem(Icons.logout, '🚪 تسجيل الخروج', () {
                        _showLogoutDialog();
                      }, color: AppColors.error),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color ?? AppColors.primary),
                title: Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(color: item.color),
                ),
                trailing: item.trailing ?? const Icon(Icons.arrow_back_ios, size: 16),
                onTap: item.onTap,
              ),
              if (item != items.last) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                try {
                  final repo = AuthRepository();
                  await repo.changePassword(
                    oldPassword: oldCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم التغيير بنجاح'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  void _showChangeConfirmationCodeDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كود التأكيد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'الكود الحالي'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'الكود الجديد'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final repo = AuthRepository();
                await repo.changeConfirmationCode(
                  oldCode: oldCtrl.text,
                  newCode: newCtrl.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم التغيير بنجاح'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _MenuItem(this.icon, this.label, this.onTap, {this.color, this.trailing});
}
