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

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data!;
      final token = data['token']?.toString() ?? data['access_token']?.toString();
      if (token == null || token.isEmpty) {
        throw const UnknownException('Token tidak ditemukan dalam respons.');
      }
      await _tokenStorage.write(token);
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>? ?? data);
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
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final data = response.data!;
      final token = data['token']?.toString() ?? data['access_token']?.toString();
      if (token == null || token.isEmpty) {
        throw const UnknownException('Token tidak ditemukan dalam respons.');
      }
      await _tokenStorage.write(token);
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>? ?? data);
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>('/api/auth/logout');
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
      final response = await _dio.get<Map<String, dynamic>>('/api/me');
      return UserProfile.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw dioToAppException(e);
    }
  }
}
