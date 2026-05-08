/// Model representing a bill service (electricity, water, internet, etc.).
class BillServiceModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String serviceCode;
  final String? category;
  final String? icon;
  final bool isActive;

  const BillServiceModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.serviceCode,
    this.category,
    this.icon,
    this.isActive = true,
  });

  factory BillServiceModel.fromJson(Map<String, dynamic> json) {
    return BillServiceModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
      serviceCode: json['serviceCode'] as String? ?? json['code'] as String? ?? '',
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'serviceCode': serviceCode,
      'category': category,
      'icon': icon,
      'isActive': isActive,
    };
  }
}
