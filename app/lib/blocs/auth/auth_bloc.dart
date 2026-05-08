import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../core/storage/secure_storage.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<PosLoginRequested>(_onPosLoginRequested);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpVerifyRequested>(_onOtpVerifyRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthKycRequested>(_onKycRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _checkAuthStatus(emit);
  }

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    await _checkAuthStatus(emit);
  }

  Future<void> _checkAuthStatus(Emitter<AuthState> emit) async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final userId = await SecureStorage.getUserId() ?? '';
        final userName = await SecureStorage.getUserName() ?? '';
        final userPhone = await SecureStorage.getUserPhone() ?? '';
        final userRole = await SecureStorage.getUserRole() ?? '';
        final isVerified = await SecureStorage.getIsVerified();

        final user = UserModel(
          id: userId,
          phone: userPhone,
          name: userName,
          role: userRole,
          status: 'ACTIVE',
          isVerified: isVerified,
          createdAt: DateTime.now(),
        );

        emit(AuthAuthenticated(user: user, token: token));
      } catch (e) {
        await SecureStorage.clearAll();
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(
        phone: event.phone,
        password: event.password,
      );
      final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      final token = result['token'] as String;
      emit(AuthAuthenticated(user: user, token: token));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPosLoginRequested(
    PosLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(
        phone: event.phone,
        password: event.password,
      );
      final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      final token = result['token'] as String;

      if (user.role == 'POS' || user.role == 'MERCHANT') {
        await SecureStorage.saveConfirmationCode(event.shortCode);
      }

      emit(AuthAuthenticated(user: user, token: token));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onOtpRequested(
    AuthOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.requestOtp(
        phone: event.phone,
        shortCode: event.shortCode,
      );
      final requestId = result['requestId'] as String?;
      emit(AuthOtpSent(phone: event.phone, requestId: requestId));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onOtpVerifyRequested(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.verifyOtp(
        phone: event.phone,
        code: event.code,
        purpose: event.purpose,
      );

      if (result['user'] != null && result['token'] != null) {
        final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
        final token = result['token'] as String;

        await SecureStorage.saveToken(token);
        await SecureStorage.saveUserId(user.id);
        await SecureStorage.saveUserRole(user.role);
        await SecureStorage.saveUserName(user.name);
        await SecureStorage.saveUserPhone(user.phone);
        await SecureStorage.saveIsVerified(user.isVerified);
        if (user.confirmationCode.isNotEmpty) {
          await SecureStorage.saveConfirmationCode(user.confirmationCode);
        }

        emit(AuthOtpVerified(user: user, token: token));
      } else {
        emit(AuthOtpVerified(
          user: UserModel(
            id: '',
            phone: event.phone,
            name: '',
            role: '',
            status: '',
            createdAt: DateTime.now(),
          ),
          token: '',
        ));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final _ = await _authRepository.register(data: {
        'name': event.name,
        'phone': event.phone,
        'password': event.password,
        if (event.gender != null) 'gender': event.gender,
      });

      // After registration, emit AuthRegistered so screen navigates to OTP
      emit(AuthRegistered(phone: event.phone));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onKycRequested(
    AuthKycRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // In a real app, this would call an API endpoint
      // For now, simulate a successful KYC submission
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        final updatedUser = currentState.user.copyWith(
          isVerified: true,
          firstName: event.firstName,
          fatherName: event.fatherName,
          grandfatherName: event.grandfatherName,
          familyName: event.familyName,
          nationalId: event.nationalId,
        );
        await SecureStorage.saveIsVerified(true);
        emit(AuthKycSubmitted(user: updatedUser, token: currentState.token));
      } else {
        emit(AuthError(message: 'غير مسجل الدخول'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await SecureStorage.clearAll();
    emit(AuthUnauthenticated());
  }
}
