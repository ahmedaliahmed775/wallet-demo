import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

class PaymentRepository {
  final ApiClient _apiClient = ApiClient();

  /// POST /api/payment/init (with auth)
  Future<Map<String, dynamic>> initPayment({
    required String senderPhone,
    required String posNumber,
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentInit,
        data: {
          'senderPhone': senderPhone,
          'posNumber': posNumber,
          'amount': amount,
          'currency': currency,
          if (description != null) 'description': description,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/payment/confirm (with auth)
  Future<Map<String, dynamic>> confirmPayment({
    required String transactionId,
    required String confirmationCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentConfirm,
        data: {
          'transactionId': transactionId,
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

  /// POST /api/payment/by-pos (with auth)
  Future<Map<String, dynamic>> payByPos({
    required String posNumber,
    required double amount,
    required String confirmationCode,
    String? currency,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentByPos,
        data: {
          'posNumber': posNumber,
          'amount': amount,
          'confirmationCode': confirmationCode,
          if (currency != null) 'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/payment/scan-qr (with auth)
  Future<Map<String, dynamic>> payByQr({
    required String qrData,
    required double amount,
    required String confirmationCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentScanQr,
        data: {
          'qrData': qrData,
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

  /// POST /api/payment/generate-code (with auth)
  Future<Map<String, dynamic>> generatePaymentCode({
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentGenerateCode,
        data: {
          'amount': amount,
          'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// POST /api/payment/refund (with auth)
  Future<Map<String, dynamic>> refundPayment({
    required String transactionId,
    required String note,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentRefund,
        data: {
          'transactionId': transactionId,
          'note': note,
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
