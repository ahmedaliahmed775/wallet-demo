import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'ar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('الوضع الداكن', style: AppTextStyles.bodyMedium),
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: const Text('الإشعارات', style: AppTextStyles.bodyMedium),
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  title: const Text('اللغة', style: AppTextStyles.bodyMedium),
                  trailing: const Text('العربية', style: AppTextStyles.bodyMedium),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: const Text('حول التطبيق', style: AppTextStyles.bodyMedium),
              subtitle: const Text('مِحْفَظ v1.0.0', style: AppTextStyles.bodySmall),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'مِحْفَظ',
                  applicationVersion: '1.0.0',
                  children: [
                    const Text('محفظتك الإلكترونية اليمنية', style: AppTextStyles.bodyMedium),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
