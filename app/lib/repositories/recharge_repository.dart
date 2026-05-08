import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class RechargeRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/recharge/operators (with auth)
  Future<List<dynamic>> getOperators() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.rechargeOperators);
      final data = response.data;
      if (data is List) {
        return data;
      }
      if (data is Map<String, dynamic>) {
        // Handle wrapped response: { "success": true, "data": [...] }
        if (data['data'] is List) {
          return data['data'] as List<dynamic>;
        }
        if (data['operators'] is List) {
          return data['operators'] as List<dynamic>;
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/recharge/apply (with auth)
  Future<Map<String, dynamic>> applyRecharge({
    required String operatorId,
    required String phone,
    required double amount,
    required String confirmationCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.rechargeApply,
        data: {
          'operatorId': operatorId,
          'phone': phone,
          'amount': amount,
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
