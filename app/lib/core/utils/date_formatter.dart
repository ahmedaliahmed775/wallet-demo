import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'منذ $weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else {
      final years = (diff.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
    }
  }

  static String formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'اليوم';
    } else if (dateOnly == yesterday) {
      return 'أمس';
    } else {
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    }
  }
}
