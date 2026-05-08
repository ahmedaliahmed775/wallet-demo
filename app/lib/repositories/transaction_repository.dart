import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class TransactionRepository {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/transactions/status (with auth)
  Future<Map<String, dynamic>> getTransactionStatus({
    String? transactionId,
    String? referenceNo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (transactionId != null) queryParams['transactionId'] = transactionId;
      if (referenceNo != null) queryParams['referenceNo'] = referenceNo;
      final response = await _apiClient.get(
        ApiEndpoints.transactionStatus,
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// GET /api/transactions/history (with auth)
  Future<Map<String, dynamic>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      final response = await _apiClient.get(
        ApiEndpoints.transactionHistory,
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// GET /api/transactions/receipt (with auth)
  Future<Map<String, dynamic>> getTransactionReceipt({
    required String transactionId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.transactionReceipt,
        queryParameters: {'transactionId': transactionId},
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
