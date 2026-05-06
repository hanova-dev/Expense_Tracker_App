
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/expenses/screens/add_expense_screen.dart';

final goRouter = GoRouter(
  initialLocation: Hive.box('settings').containsKey('globalCurrency') ? '/dashboard' : '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => const AddExpenseScreen(),
    ),
  ],
);
