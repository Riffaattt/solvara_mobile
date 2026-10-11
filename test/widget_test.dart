import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_salvara/app/app.dart';
import 'package:hackathon_salvara/features/auth/auth_state.dart';
import 'package:hackathon_salvara/features/auth/domain/auth_repository.dart';
import 'package:hackathon_salvara/features/auth/domain/user_profile.dart';

/// Fake auth repo that returns null from getMe (unauthenticated).
class _FakeAuthRepo implements AuthRepository {
  @override
  Future<UserProfile> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<UserProfile?> getMe() async => null;
}

void main() {
  testWidgets('App renders without crashing (unauthenticated)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
        ],
        child: const SolvaraApp(),
      ),
    );
    // Pump a few frames so auth future and router redirect resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SolvaraApp), findsOneWidget);
  });
}
