import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final String id;
  final String userId;
  final String currency;
  final double balance;
  final String walletNumber;
  final bool isDefault;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    required this.walletNumber,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, userId, currency, balance, walletNumber, isDefault];

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: (json['id'] as String?) ?? '',
      userId: json['userId'] as String? ?? '',
      currency: (json['currency'] as String?) ?? 'YER',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      walletNumber: (json['walletNumber'] as String?) ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'currency': currency,
      'balance': balance,
      'walletNumber': walletNumber,
      'isDefault': isDefault,
    };
  }

  String get currencySymbol => getCurrencySymbol(currency);

  String get currencyName => getCurrencyNameAr(currency);

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

  WalletModel copyWith({
    String? id,
    String? userId,
    String? currency,
    double? balance,
    String? walletNumber,
    bool? isDefault,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      walletNumber: walletNumber ?? this.walletNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
