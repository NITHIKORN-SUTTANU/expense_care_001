import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/recurring_expenses_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/summary/presentation/screens/summary_screen.dart';
import '../../shared/widgets/main_shell.dart';

class AppRoutes {
  static const String home = '/home';
  static const String goals = '/goals';
  static const String summary = '/summary';
  static const String profile = '/profile';
  static const String profileRecurring = '/profile/recurring';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: AppRoutes.goals,
            builder: (context, state) => const GoalsScreen()),
        GoRoute(
            path: AppRoutes.summary,
            builder: (context, state) => const SummaryScreen()),
        GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen()),
      ],
    ),
    GoRoute(
        path: AppRoutes.profileRecurring,
        builder: (context, state) => const RecurringExpensesScreen()),
  ],
);
