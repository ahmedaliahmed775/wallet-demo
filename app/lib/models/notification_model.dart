class NotificationModel {
  final String id;
  final String titleAr;
  final String messageAr;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.titleAr,
    required this.messageAr,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  /// Convenience getter for title (Arabic).
  String get title => titleAr;

  /// Convenience getter for message (Arabic).
  String get message => messageAr;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String? ?? json['title'] as String? ?? '',
      messageAr: json['messageAr'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleAr': titleAr,
      'messageAr': messageAr,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? titleAr,
    String? messageAr,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      messageAr: messageAr ?? this.messageAr,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
