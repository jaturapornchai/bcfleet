import 'package:dio/dio.dart';

/// FleetApiClient — HTTP client สำหรับเชื่อมต่อ BC Fleet API
class FleetApiClient {
  final Dio _dio;

  FleetApiClient({required String baseUrl, required String token})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));

  /// อัปเดต token (หลัง login/refresh)
  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// GET request พร้อม pagination
  Future<ApiResponse> get(String path, {Map<String, dynamic>? queryParams}) async {
    final response = await _dio.get(path, queryParameters: queryParams);
    return ApiResponse.fromResponse(response);
  }

  /// POST request
  Future<ApiResponse> post(String path, {dynamic data}) async {
    final response = await _dio.post(path, data: data);
    return ApiResponse.fromResponse(response);
  }

  /// PUT request
  Future<ApiResponse> put(String path, {dynamic data}) async {
    final response = await _dio.put(path, data: data);
    return ApiResponse.fromResponse(response);
  }

  /// DELETE request
  Future<ApiResponse> delete(String path) async {
    final response = await _dio.delete(path);
    return ApiResponse.fromResponse(response);
  }

  /// Upload file
  Future<ApiResponse> upload(String path, String filePath, {String fieldName = 'file'}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(path, data: formData);
    return ApiResponse.fromResponse(response);
  }
}

/// ApiResponse — response wrapper
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? error;
  final int? total;
  final int? page;
  final int? limit;

  ApiResponse({
    required this.statusCode,
    this.data,
    this.error,
    this.total,
    this.page,
    this.limit,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  factory ApiResponse.fromResponse(Response response) {
    final body = response.data;
    return ApiResponse(
      statusCode: response.statusCode ?? 500,
      data: body is Map ? body['data'] : body,
      error: body is Map ? body['error'] as String? : null,
      total: body is Map ? body['total'] as int? : null,
      page: body is Map ? body['page'] as int? : null,
      limit: body is Map ? body['limit'] as int? : null,
    );
  }
}
