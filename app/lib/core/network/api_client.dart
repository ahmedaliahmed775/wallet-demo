import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await SecureStorage.clearAll();
        }
        handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Dio get dio => _dio;

  /// Extracts the inner `data` payload from the server's standard response
  /// format: `{ "success": true, "data": { ... } }`.
  /// If `data` key exists and is a Map, returns it; otherwise returns the
  /// original body so the app works whether the server wraps or not.
  dynamic _unwrapResponse(dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) return inner;
      if (inner is List) return inner;
    }
    return body;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters).then((response) {
      response.data = _unwrapResponse(response.data);
      return response;
    });
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data).then((response) {
      response.data = _unwrapResponse(response.data);
      return response;
    });
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data).then((response) {
      response.data = _unwrapResponse(response.data);
      return response;
    });
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data).then((response) {
      response.data = _unwrapResponse(response.data);
      return response;
    });
  }
}
