import 'package:equatable/equatable.dart';
import 'wallet_model.dart';
import 'merchant_model.dart';

class UserModel extends Equatable {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String role;
  final String status;
  final String? gender;
  final String? firstName;
  final String? fatherName;
  final String? grandfatherName;
  final String? familyName;
  final String? nationalId;
  final String confirmationCode;
  final bool isVerified;
  final bool isIdentityHidden;
  final String language;
  final DateTime createdAt;
  final List<WalletModel>? wallets;
  final MerchantModel? merchant;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.role,
    required this.status,
    this.gender,
    this.firstName,
    this.fatherName,
    this.grandfatherName,
    this.familyName,
    this.nationalId,
    this.confirmationCode = '1234',
    this.isVerified = false,
    this.isIdentityHidden = false,
    this.language = 'ar',
    required this.createdAt,
    this.wallets,
    this.merchant,
  });

  @override
  List<Object?> get props => [
        id, phone, name, email, role, status, gender,
        firstName, fatherName, grandfatherName, familyName, nationalId,
        confirmationCode, isVerified, isIdentityHidden, language,
        createdAt, wallets, merchant,
      ];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: json['email'] as String?,
      role: (json['role'] as String?) ?? 'CUSTOMER',
      status: (json['status'] as String?) ?? 'ACTIVE',
      gender: json['gender'] as String?,
      firstName: json['firstName'] as String?,
      fatherName: json['fatherName'] as String?,
      grandfatherName: json['grandfatherName'] as String?,
      familyName: json['familyName'] as String?,
      nationalId: json['nationalId'] as String?,
      confirmationCode: json['confirmationCode'] as String? ?? '1234',
      isVerified: json['isVerified'] as bool? ?? false,
      isIdentityHidden: json['isIdentityHidden'] as bool? ?? false,
      language: json['language'] as String? ?? 'ar',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      wallets: json['wallets'] != null
          ? (json['wallets'] as List<dynamic>)
              .map((e) => WalletModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      merchant: json['merchant'] != null
          ? MerchantModel.fromJson(json['merchant'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'gender': gender,
      'firstName': firstName,
      'fatherName': fatherName,
      'grandfatherName': grandfatherName,
      'familyName': familyName,
      'nationalId': nationalId,
      'confirmationCode': confirmationCode,
      'isVerified': isVerified,
      'isIdentityHidden': isIdentityHidden,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'wallets': wallets?.map((e) => e.toJson()).toList(),
      'merchant': merchant?.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? role,
    String? status,
    String? gender,
    String? firstName,
    String? fatherName,
    String? grandfatherName,
    String? familyName,
    String? nationalId,
    String? confirmationCode,
    bool? isVerified,
    bool? isIdentityHidden,
    String? language,
    DateTime? createdAt,
    List<WalletModel>? wallets,
    MerchantModel? merchant,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      firstName: firstName ?? this.firstName,
      fatherName: fatherName ?? this.fatherName,
      grandfatherName: grandfatherName ?? this.grandfatherName,
      familyName: familyName ?? this.familyName,
      nationalId: nationalId ?? this.nationalId,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      isVerified: isVerified ?? this.isVerified,
      isIdentityHidden: isIdentityHidden ?? this.isIdentityHidden,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      wallets: wallets ?? this.wallets,
      merchant: merchant ?? this.merchant,
    );
  }
}
