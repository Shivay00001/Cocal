import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../config/supabase_config.dart';
import '../screens/screens.dart';
import '../providers/providers.dart';
import '../screens/auth/forgot_password_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(),
    redirect: (context, state) {
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final isAuthRoute = state.uri.path == '/login' ||
                         state.uri.path == '/signup' ||
                         state.uri.path == '/forgot-password';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && (state.uri.path == '/login' || state.uri.path == '/signup')) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(context, state, const HomeScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _buildPage(context, state, const SignUpScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildPage(context, state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPage(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _buildPage(context, state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/add-food',
        pageBuilder: (context, state) => _buildPage(context, state, const AddFoodScreen()),
      ),
      GoRoute(
        path: '/packaged-food',
        pageBuilder: (context, state) => _buildPage(context, state, const PackagedFoodScreen()),
      ),
      GoRoute(
        path: '/add-weight',
        pageBuilder: (context, state) => _buildPage(context, state, const AddWeightScreen()),
      ),
      GoRoute(
        path: '/evening-review',
        pageBuilder: (context, state) => _buildPage(context, state, const EveningReviewScreen()),
      ),
      GoRoute(
        path: '/premium',
        pageBuilder: (context, state) => _buildPage(context, state, const PremiumScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => _buildPage(context, state, const ReportsScreen()),
      ),
      GoRoute(
        path: '/habits',
        pageBuilder: (context, state) => _buildPage(context, state, const HabitsScreen()),
      ),
      GoRoute(
        path: '/add-exercise',
        pageBuilder: (context, state) => _buildPage(context, state, const AddExerciseScreen()),
      ),
      GoRoute(
        path: '/streaks',
        pageBuilder: (context, state) => _buildPage(context, state, const StreakScreen()),
      ),
      GoRoute(
        path: '/competitions',
        pageBuilder: (context, state) => _buildPage(context, state, const CompetitorScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildPage(context, state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) => _buildPage(context, state, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/help-support',
        pageBuilder: (context, state) => _buildPage(context, state, const HelpSupportScreen()),
      ),
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) => _buildPage(context, state, const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: '/calorie-calculator',
        pageBuilder: (context, state) => _buildPage(context, state, const CalorieCalculatorScreen()),
      ),
    ],
  );
});

Page<void> _buildPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream() {
    notifyListeners();
    _subscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
      (data) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
