import 'package:hackathon_salvara/features/auth/domain/user_profile.dart';

/// Contract for auth operations.
abstract interface class AuthRepository {
  Future<UserProfile> login({required String email, required String password});

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<void> logout();

  Future<UserProfile?> getMe();
}
