import 'package:dio/dio.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/core/storage/token_storage.dart';

/// Base URL for the Laravel backend (without trailing slash).
/// Override at build/run time: `--dart-define=API_BASE_URL=https://your-ngrok-url`
const String _kDefaultBaseUrl = 'https://a321-2402-8780-106a-28a5-85fd-2a5c-49d2-970f.ngrok-free.app';

/// All citizen endpoints live under /api/v1.
/// Trailing slash is required: Dio resolves relative paths against it.
const String _kApiPrefix = '/api/v1/';

/// Creates and configures the shared [Dio] instance.
Dio buildDioClient(TokenStorage tokenStorage) {
  final base = const String.fromEnvironment('API_BASE_URL', defaultValue: _kDefaultBaseUrl);
  final dio = Dio(
    BaseOptions(
      baseUrl: '$base$_kApiPrefix',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        // Prevents ngrok from returning its browser-warning HTML page.
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  dio.interceptors.add(_AuthInterceptor(tokenStorage));
  // shortcut: remove LogInterceptor before production build
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
}

/// Attaches Bearer token to every request and handles 401 globally.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
      return;
    }
    handler.next(err);
  }
}

/// Converts a [DioException] to a typed [AppException].
AppException dioToAppException(DioException e) {
  if (e.error is AppException) return e.error! as AppException;

  final statusCode = e.response?.statusCode;

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const NetworkException('Koneksi habis waktu. Periksa jaringan Anda.');
  }

  if (e.type == DioExceptionType.connectionError) {
    return const NetworkException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
  }

  if (statusCode == 422 || statusCode == 400) {
    final data = e.response?.data;
    final errors = <String, List<String>>{};
    // Backend envelope: {"error": {"code": "...", "message": "...", "fields": {...}}}
    final errorObj = data is Map ? data['error'] : null;
    if (errorObj is Map && errorObj['fields'] is Map) {
      (errorObj['fields'] as Map).forEach((k, v) {
        if (v is List) {
          errors[k.toString()] = v.map((e) => e.toString()).toList();
        } else {
          errors[k.toString()] = [v.toString()];
        }
      });
    }
    final message = (errorObj is Map ? errorObj['message']?.toString() : null) ?? 'Data tidak valid.';
    return ValidationException(message, errors: errors);
  }

  // Extract message from backend envelope for any other error status.
  final data = e.response?.data;
  final errorObj = data is Map ? data['error'] : null;
  final serverMessage = errorObj is Map ? errorObj['message']?.toString() : null;

  if (statusCode != null && statusCode >= 500) {
    return NetworkException(
      serverMessage ?? 'Server bermasalah (kode $statusCode). Coba lagi nanti.',
      statusCode: statusCode,
    );
  }

  return UnknownException(
    serverMessage ?? e.message ?? 'Terjadi kesalahan yang tidak diketahui.',
  );
}
