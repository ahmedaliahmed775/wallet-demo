import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class CashRepository {
  final ApiClient _apiClient = ApiClient();

  /// POST /api/cash/deposit (with auth)
  Future<Map<String, dynamic>> deposit({
    required String agentWallet,
    required double amount,
    required String currency,
    required String receiverPhone,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.cashDeposit,
        data: {
          'agentWallet': agentWallet,
          'amount': amount,
          'currency': currency,
          'receiverPhone': receiverPhone,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/cash/withdraw (with auth)
  Future<Map<String, dynamic>> withdraw({
    required String agentWallet,
    required double amount,
    required String currency,
    required String confirmationCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.cashWithdraw,
        data: {
          'agentWallet': agentWallet,
          'amount': amount,
          'currency': currency,
          'confirmationCode': confirmationCode,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// GET /api/cash/agents-nearby (with auth)
  Future<List<dynamic>> getNearbyAgents() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.cashAgents);
      final data = response.data;
      if (data is List) {
        return data;
      }
      if (data is Map<String, dynamic>) {
        // Handle wrapped response: { "success": true, "data": [...] }
        if (data['data'] is List) {
          return data['data'] as List<dynamic>;
        }
        if (data['agents'] is List) {
          return data['agents'] as List<dynamic>;
        }
      }
      return [];
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
