part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStatusChecked extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String password;
  const AuthLoginRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

class PosLoginRequested extends AuthEvent {
  final String phone;
  final String shortCode;
  final String password;
  const PosLoginRequested({required this.phone, required this.shortCode, required this.password});

  @override
  List<Object?> get props => [phone, shortCode, password];
}

class AuthOtpRequested extends AuthEvent {
  final String phone;
  final String shortCode;
  final String? purpose;
  const AuthOtpRequested({required this.phone, required this.shortCode, this.purpose});

  @override
  List<Object?> get props => [phone, shortCode, purpose];
}

class AuthOtpVerifyRequested extends AuthEvent {
  final String phone;
  final String code;
  final String purpose;
  const AuthOtpVerifyRequested({required this.phone, required this.code, required this.purpose});

  @override
  List<Object?> get props => [phone, code, purpose];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String password;
  final String? gender;
  const AuthRegisterRequested({
    required this.name,
    required this.phone,
    required this.password,
    this.gender,
  });

  @override
  List<Object?> get props => [name, phone, password, gender];
}

class AuthKycRequested extends AuthEvent {
  final String nationalId;
  final String firstName;
  final String fatherName;
  final String grandfatherName;
  final String familyName;
  const AuthKycRequested({
    required this.nationalId,
    required this.firstName,
    required this.fatherName,
    required this.grandfatherName,
    required this.familyName,
  });

  @override
  List<Object?> get props => [nationalId, firstName, fatherName, grandfatherName, familyName];
}

class AuthLogoutRequested extends AuthEvent {}
