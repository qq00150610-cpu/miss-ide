// lib/admin_app.dart - 管理后台主应用
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/users/user_list_page.dart';
import 'features/users/user_detail_page.dart';
import 'features/analytics/analytics_page.dart';
import 'features/settings/settings_page.dart';
import 'shared/widgets/admin_shell.dart';

void main() {
  runApp(const MissAdminApp());
}

class MissAdminApp extends StatelessWidget {
  const MissAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Miss IDE Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/users',
          name: 'users',
          builder: (context, state) => const UserListPage(),
          routes: [
            GoRoute(
              path: ':userId',
              name: 'user-detail',
              builder: (context, state) => UserDetailPage(
                userId: state.pathParameters['userId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
