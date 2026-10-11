import 'package:dio/dio.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/core/network/dio_client.dart';
import 'package:hackathon_salvara/core/storage/token_storage.dart';
import 'package:hackathon_salvara/features/auth/domain/auth_repository.dart';
import 'package:hackathon_salvara/features/auth/domain/user_profile.dart';

/// Implements [AuthRepository] using the Laravel REST API.
class AuthRemoteDataSource implements AuthRepository {
  AuthRemoteDataSource(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Unwraps `{"data": {...}}` envelope.
  Map<String, dynamic> _data(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return body['data'] as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/login',
        data: {'email': email, 'password': password},
      );
      final data = _data(response.data);
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const UnknownException('Token tidak ditemukan dalam respons.');
      }
      await _tokenStorage.write(token);
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return UserProfile.fromJson(userJson);
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final data = _data(response.data);
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const UnknownException('Token tidak ditemukan dalam respons.');
      }
      await _tokenStorage.write(token);
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return UserProfile.fromJson(userJson);
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>('auth/logout');
    } on DioException catch (e) {
      // Ignore 401 on logout — token may already be invalid.
      if (e.response?.statusCode != 401) rethrow;
    } finally {
      await _tokenStorage.delete();
    }
  }

  @override
  Future<UserProfile?> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('auth/me');
      final data = _data(response.data);
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw dioToAppException(e);
    }
  }
}
