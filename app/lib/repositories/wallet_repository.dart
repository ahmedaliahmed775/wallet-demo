import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class WalletRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/wallet/balance (with auth)
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletBalance);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// GET /api/wallet/info (with auth)
  Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletInfo);
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
