/// Model representing a mobile recharge operator (Yemen Mobile, Sabafon, MTN, Y).
class RechargeOperatorModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? logo;
  final bool isActive;

  const RechargeOperatorModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.logo,
    this.isActive = true,
  });

  factory RechargeOperatorModel.fromJson(Map<String, dynamic> json) {
    return RechargeOperatorModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'logo': logo,
      'isActive': isActive,
    };
  }
}
