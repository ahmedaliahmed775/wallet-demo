import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/secure_storage.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  /// POST /api/auth/login
  /// After login success, saves token, role, userId, userName, userPhone to SecureStorage.
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );
      final result = response.data as Map<String, dynamic>;

      // Save auth data to secure storage on success
      if (result['token'] != null) {
        await SecureStorage.saveToken(result['token'] as String);
      }
      if (result['user'] != null) {
        final user = result['user'] as Map<String, dynamic>;
        if (user['id'] != null) {
          await SecureStorage.saveUserId(user['id'].toString());
        }
        if (user['role'] != null) {
          await SecureStorage.saveUserRole(user['role'] as String);
        }
        if (user['name'] != null) {
          await SecureStorage.saveUserName(user['name'] as String);
        }
        if (user['phone'] != null) {
          await SecureStorage.saveUserPhone(user['phone'] as String);
        }
        if (user['isVerified'] != null) {
          await SecureStorage.saveIsVerified(user['isVerified'] as bool);
        }
        if (user['confirmationCode'] != null) {
          await SecureStorage.saveConfirmationCode(user['confirmationCode'] as String);
        }
      }

      return result;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/auth/request-otp
  Future<Map<String, dynamic>> requestOtp({
    required String phone,
    required String shortCode,
    String purpose = 'LOGIN',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.requestOtp,
        data: {'phone': phone, 'purpose': purpose},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'code': code, 'purpose': purpose},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/auth/change-password (with auth)
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/auth/change-confirmation-code (with auth)
  Future<void> changeConfirmationCode({
    required String oldCode,
    required String newCode,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.changeConfirmationCode,
        data: {'oldCode': oldCode, 'newCode': newCode},
      );
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  String _extractDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return 'لا يمكن الاتصال بالخادم';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['error']?['message'] as String? ??
          data['message'] as String? ??
          'حدث خطأ غير متوقع';
    }
    if (data is String) {
      return data;
    }
    return 'حدث خطأ غير متوقع';
  }
}
