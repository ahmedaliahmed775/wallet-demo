class ServiceModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final String category;
  final bool isActive;
  final int sortOrder;

  ServiceModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.category,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json['id'] as String?) ?? '',
      nameAr: (json['nameAr'] as String?) ?? '',
      nameEn: (json['nameEn'] as String?) ?? '',
      icon: json['icon'] as String? ?? '',
      category: (json['category'] as String?) ?? '',
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'icon': icon,
      'category': category,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? icon,
    String? category,
    bool? isActive,
    int? sortOrder,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
