import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/expenses/presentation/expense_detail_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/scanner/presentation/review_expense_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Listenable đồng bộ trạng thái đăng nhập Firebase Auth với GoRouter
class FirebaseAuthListenable extends ChangeNotifier {
  FirebaseAuthListenable() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((_) {
        notifyListeners();
      });
    } catch (_) {}
    AuthRepository.authStateListenable.addListener(notifyListeners);
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: FirebaseAuthListenable(),
  redirect: (context, state) {
    final isAuthenticated = AuthRepository.isAuthenticated;
    final loc = state.matchedLocation;
    final isAuthRoute =
        loc == '/login' || loc == '/register' || loc == '/forgot-password';

    // Chưa đăng nhập và đang cố truy cập route được bảo vệ
    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    // Đã đăng nhập và đang ở các trang Auth -> chuyển về Dashboard
    if (isAuthenticated && isAuthRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    // Authentication Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // ShellRoute for Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        // Tab 1: Expenses
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const ExpensesScreen(),
            ),
          ],
        ),
        // Tab 2: Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Fullscreen Scanner Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scan',
      builder: (context, state) => const ScannerScreen(),
    ),
    // Review Expense Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/review',
      builder: (context, state) => const ReviewExpenseScreen(),
    ),
    // Expense Detail Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/expenses/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '';
        return ExpenseDetailScreen(expenseId: idStr);
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Chi tiêu',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
