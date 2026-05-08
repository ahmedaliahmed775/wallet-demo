import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(ApiEndpoints.notifications);
      final data = response.data;
      if (data is List) {
        setState(() {
          _notifications = data
              .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else if (data is Map<String, dynamic>) {
        final list = data['data'] is Map
            ? data['data']['notifications']
            : data['notifications'] ?? [];
        setState(() {
          _notifications = (list is List)
              ? list.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList()
              : [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? AppColors.surface
                                : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: notification.isRead
                                  ? AppColors.divider
                                  : AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getTypeIcon(notification.type),
                                  color: _getTypeColor(notification.type),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.title,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification.message,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormatter.formatRelative(notification.createdAt),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'TRANSACTION':
        return AppColors.primary;
      case 'SYSTEM':
        return AppColors.info;
      case 'PROMO':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'TRANSACTION':
        return Icons.receipt;
      case 'SYSTEM':
        return Icons.info;
      case 'PROMO':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}
