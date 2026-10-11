import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hackathon_salvara/core/providers.dart';
import 'package:hackathon_salvara/features/auth/data/auth_remote_data_source.dart';
import 'package:hackathon_salvara/features/auth/domain/auth_repository.dart';
import 'package:hackathon_salvara/features/auth/domain/user_profile.dart';

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// The current authentication state of the app.
enum AuthStatus { loading, authenticated, unauthenticated }

/// Holds auth status and the current user profile.
class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final UserProfile? user;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, UserProfile? user}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}

/// Manages auth lifecycle: startup check, login, register, logout.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  // ignore: invalid_override_of_non_virtual_member
  AuthState build() {
    // Return synchronously — no async, no storage read, no network.
    // flutter_secure_storage blocks on vivo/OPPO/Xiaomi causing infinite splash.
    // Token is attached per-request by _AuthInterceptor; session persists in memory.
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
          );
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

/// Global auth state provider.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
