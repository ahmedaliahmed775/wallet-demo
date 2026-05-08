class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    if (!value.startsWith('967') || value.length != 12) {
      return 'رقم الهاتف غير صحيح (يجب أن يبدأ بـ 967)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'المبلغ مطلوب';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'المبلغ غير صحيح';
    }
    return null;
  }

  static String? validateConfirmationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'كود التأكيد مطلوب';
    }
    if (value.length != 4) {
      return 'كود التأكيد يجب أن يكون 4 أرقام';
    }
    return null;
  }

  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? validateShortCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرمز القصير مطلوب';
    }
    if (value.length != 6) {
      return 'الرمز القصير يجب أن يكون 6 أرقام';
    }
    return null;
  }

  static String? validatePosNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم نقطة البيع مطلوب';
    }
    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الحساب مطلوب';
    }
    if (value.length < 3) {
      return 'رقم الحساب غير صحيح';
    }
    return null;
  }

  static String formatPhoneWithPrefix(String phone) {
    if (phone.startsWith('967')) {
      return phone;
    }
    if (phone.startsWith('0')) {
      return '967${phone.substring(1)}';
    }
    return '967$phone';
  }

  static String stripPhonePrefix(String phone) {
    if (phone.startsWith('967')) {
      return phone.substring(3);
    }
    if (phone.startsWith('0')) {
      return phone.substring(1);
    }
    return phone;
  }
}
