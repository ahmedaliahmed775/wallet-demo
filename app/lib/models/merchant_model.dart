class MerchantModel {
  final String id;
  final String userId;
  final String businessName;
  final String shortCode;
  final String terminalNumber;
  final String? category;
  final bool isActive;

  MerchantModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.shortCode,
    required this.terminalNumber,
    this.category,
    this.isActive = true,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      businessName: json['businessName'] as String,
      shortCode: json['shortCode'] as String,
      terminalNumber: json['terminalNumber'] as String? ?? '',
      category: json['category'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'shortCode': shortCode,
      'terminalNumber': terminalNumber,
      'category': category,
      'isActive': isActive,
    };
  }

  MerchantModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? shortCode,
    String? terminalNumber,
    String? category,
    bool? isActive,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      shortCode: shortCode ?? this.shortCode,
      terminalNumber: terminalNumber ?? this.terminalNumber,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}
