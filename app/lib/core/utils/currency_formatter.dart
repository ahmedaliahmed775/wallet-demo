class CurrencyFormatter {
  static String format(double amount, {String currency = 'YER'}) {
    String formatted = amount.toStringAsFixed(0);
    // Add comma separators
    RegExp regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    formatted = formatted.replaceAll(regex, ',');

    switch (currency) {
      case 'YER':
        return '$formatted ر.ي';
      case 'USD':
        return '\$$formatted';
      case 'SAR':
        return '$formatted ر.س';
      default:
        return formatted;
    }
  }

  static String formatWithoutSymbol(double amount) {
    String formatted = amount.toStringAsFixed(0);
    RegExp regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAll(regex, ',');
  }

  static String formatWithDecimals(double amount, {String currency = 'YER'}) {
    String formatted = amount.toStringAsFixed(2);
    RegExp regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    formatted = formatted.replaceAll(regex, ',');

    switch (currency) {
      case 'YER':
        return '$formatted ر.ي';
      case 'USD':
        return '\$$formatted';
      case 'SAR':
        return '$formatted ر.س';
      default:
        return formatted;
    }
  }

  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'YER':
        return 'ر.ي';
      case 'USD':
        return '\$';
      case 'SAR':
        return 'ر.س';
      default:
        return currency;
    }
  }

  static String getCurrencyNameAr(String currency) {
    switch (currency) {
      case 'YER':
        return 'ريال يمني';
      case 'USD':
        return 'دولار أمريكي';
      case 'SAR':
        return 'ريال سعودي';
      default:
        return currency;
    }
  }

  static double convert(double amount, String from, String to) {
    if (from == to) return amount;
    double amountInYER;
    switch (from) {
      case 'YER':
        amountInYER = amount;
        break;
      case 'USD':
        amountInYER = amount * 530;
        break;
      case 'SAR':
        amountInYER = amount * 141;
        break;
      default:
        return amount;
    }
    switch (to) {
      case 'YER':
        return (amountInYER).roundToDouble();
      case 'USD':
        return (amountInYER * (1 / 530) * 100).roundToDouble() / 100;
      case 'SAR':
        return (amountInYER * (1 / 141) * 100).roundToDouble() / 100;
      default:
        return amount;
    }
  }

  static String formatWithArabicNumbers(double amount, {String currency = 'YER'}) {
    final symbol = getCurrencySymbol(currency);
    final formattedAmount = _toArabicNumbers(formatWithoutSymbol(amount));
    return '$formattedAmount $symbol';
  }

  static String _toArabicNumbers(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => arabicDigits[int.parse(match.group(0)!)],
    );
  }
}
