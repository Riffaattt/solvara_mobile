import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackathon_salvara/features/auth/auth_state.dart';
import 'package:hackathon_salvara/features/auth/presentation/login_screen.dart';
import 'package:hackathon_salvara/features/auth/presentation/register_screen.dart';
import 'package:hackathon_salvara/features/auth/presentation/splash_screen.dart';
import 'package:hackathon_salvara/features/reports/presentation/create_report_screen.dart';
import 'package:hackathon_salvara/features/reports/presentation/feedback_screen.dart';
import 'package:hackathon_salvara/features/reports/presentation/report_detail_screen.dart';
import 'package:hackathon_salvara/features/reports/presentation/reports_screen.dart';
import 'package:hackathon_salvara/features/reports/presentation/submission_tracking_screen.dart';

/// Named route paths.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const reports = '/reports';
  static const createReport = '/reports/create';
  static String reportDetail(String id) => '/reports/$id';
  static String feedback(String id) => '/reports/$id/feedback';
  static String submissionTracking(String id) => '/submissions/$id';
}

/// Builds the [GoRouter] with auth redirect logic.
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);

      // Still loading — don't redirect, stay on current route (splash).
      // Returning AppRoutes.splash here causes an infinite redirect loop.
      if (authAsync.isLoading) return null;

      // Error state (network down at startup) → treat as unauthenticated.
      final auth = authAsync.valueOrNull ??
          const AuthState(status: AuthStatus.unauthenticated);

      final onSplash = state.matchedLocation == AppRoutes.splash;
      final onAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Always leave splash once auth resolves.
      if (onSplash) {
        return auth.isAuthenticated ? AppRoutes.reports : AppRoutes.login;
      }
      // Redirect away from login/register if already authenticated.
      if (auth.isAuthenticated && onAuthPage) return AppRoutes.reports;
      // Redirect to login if unauthenticated and on a protected route.
      if (!auth.isAuthenticated && !onAuthPage) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (ctx, st) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (ctx, st) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (ctx, st) => const RegisterScreen()),
      GoRoute(path: AppRoutes.reports, builder: (ctx, st) => const ReportsScreen()),
      GoRoute(path: AppRoutes.createReport, builder: (ctx, st) => const CreateReportScreen()),
      GoRoute(
        path: '/reports/:id',
        builder: (ctx, st) => ReportDetailScreen(reportId: st.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'feedback',
            builder: (ctx, st) =>
                FeedbackScreen(reportId: st.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/submissions/:id',
        builder: (ctx, st) =>
            SubmissionTrackingScreen(submissionId: st.pathParameters['id']!),
      ),
    ],
  );
}

/// Makes [GoRouter] react to auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authStateProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;
}
