import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class TransferRepository {
  final ApiClient _apiClient = ApiClient();

  /// POST /api/transfer (with auth)
  Future<Map<String, dynamic>> transfer({
    required String receiverPhone,
    required double amount,
    required String currency,
    String? note,
    required String confirmationCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.transfer,
        data: {
          'receiverPhone': receiverPhone,
          'amount': amount,
          'currency': currency,
          if (note != null) 'note': note,
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

  /// POST /api/transfer/between-accounts (with auth)
  Future<Map<String, dynamic>> transferBetweenAccounts({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required String confirmationCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.transferBetweenAccounts,
        data: {
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
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
