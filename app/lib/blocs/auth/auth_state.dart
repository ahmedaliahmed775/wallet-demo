part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;
  const AuthAuthenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthOtpSent extends AuthState {
  final String phone;
  final String? requestId;
  const AuthOtpSent({required this.phone, this.requestId});

  @override
  List<Object?> get props => [phone, requestId];
}

class AuthOtpVerified extends AuthState {
  final UserModel user;
  final String token;
  const AuthOtpVerified({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthRegistered extends AuthState {
  final String phone;
  const AuthRegistered({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthKycSubmitted extends AuthState {
  final UserModel user;
  final String token;
  const AuthKycSubmitted({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
