import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/recurring_expenses_screen.dart';
import '../../features/summary/presentation/screens/summary_screen.dart';
import '../../shared/widgets/main_shell.dart';

class AppRoutes {
  AppRoutes._();
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String goals = '/goals';
  static const String summary = '/summary';
  static const String profile = '/profile';
  static const String profileRecurring = '/profile/recurring';
}

/// Listens to Firebase auth state and notifies GoRouter to re-evaluate redirects.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefreshNotifier = _AuthRefreshNotifier();

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: _authRefreshNotifier,
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;

    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
    if (isLoggedIn && isAuthRoute) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignUpScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.goals,
          builder: (context, state) => const GoalsScreen(),
        ),
        GoRoute(
          path: AppRoutes.summary,
          builder: (context, state) => const SummaryScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.profileRecurring,
      builder: (context, state) => const RecurringExpensesScreen(),
    ),
  ],
);
