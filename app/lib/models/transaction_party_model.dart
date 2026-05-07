/// Model representing a party (sender or receiver) in a transaction receipt.
class TransactionParty {
  final String? name;
  final String? phone;
  final String? walletNumber;

  const TransactionParty({
    this.name,
    this.phone,
    this.walletNumber,
  });

  factory TransactionParty.fromJson(Map<String, dynamic> json) {
    return TransactionParty(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      walletNumber: json['walletNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'walletNumber': walletNumber,
    };
  }
}
