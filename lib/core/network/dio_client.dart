import 'package:dio/dio.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/core/storage/token_storage.dart';

/// Base URL for the Laravel backend.
/// Set via `--dart-define=API_BASE_URL=https://...` at build time.
const String _kDefaultBaseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

/// Creates and configures the shared [Dio] instance.
Dio buildDioClient(TokenStorage tokenStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: _kDefaultBaseUrl),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(tokenStorage));
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

  if (statusCode == 422) {
    final data = e.response?.data;
    final errors = <String, List<String>>{};
    if (data is Map && data['errors'] is Map) {
      (data['errors'] as Map).forEach((k, v) {
        if (v is List) errors[k.toString()] = v.map((e) => e.toString()).toList();
      });
    }
    final message = (data is Map ? data['message']?.toString() : null) ?? 'Data tidak valid.';
    return ValidationException(message, errors: errors);
  }

  if (statusCode != null && statusCode >= 500) {
    return NetworkException('Server bermasalah (kode $statusCode). Coba lagi nanti.', statusCode: statusCode);
  }

  return UnknownException(
    e.message ?? 'Terjadi kesalahan yang tidak diketahui.',
  );
}
