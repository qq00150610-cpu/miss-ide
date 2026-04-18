// lib/app/app_router.dart - Miss IDE 路由配置
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/project/presentation/pages/home_page.dart';
import '../features/project/presentation/pages/project_page.dart';
import '../features/editor/presentation/pages/editor_page.dart';
import '../features/diff/presentation/pages/diff_page.dart';
import '../features/diff/presentation/pages/merge_page.dart';
import '../features/decompile/presentation/pages/decompile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';

/// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String project = '/project';
  static const String editor = '/editor';
  static const String diff = '/diff';
  static const String merge = '/merge';
  static const String decompile = '/decompile';
  static const String settings = '/settings';
}

/// 路由配置Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.project,
        name: 'project',
        builder: (context, state) {
          final projectPath = state.uri.queryParameters['path'];
          return ProjectPage(projectPath: projectPath);
        },
      ),
      GoRoute(
        path: AppRoutes.editor,
        name: 'editor',
        builder: (context, state) {
          final filePath = state.uri.queryParameters['path'];
          return EditorPage(filePath: filePath);
        },
      ),
      GoRoute(
        path: AppRoutes.diff,
        name: 'diff',
        builder: (context, state) {
          final leftPath = state.uri.queryParameters['left'];
          final rightPath = state.uri.queryParameters['right'];
          return DiffPage(leftPath: leftPath, rightPath: rightPath);
        },
      ),
      GoRoute(
        path: AppRoutes.decompile,
        name: 'decompile',
        builder: (context, state) {
          final apkPath = state.uri.queryParameters['apk'];
          return DecompilePage(apkPath: apkPath);
        },
      ),
      GoRoute(
        path: AppRoutes.merge,
        name: 'merge',
        builder: (context, state) {
          final basePath = state.uri.queryParameters['base'] ?? '';
          final localPath = state.uri.queryParameters['local'] ?? '';
          final remotePath = state.uri.queryParameters['remote'] ?? '';
          return MergePage(
            basePath: basePath,
            localPath: localPath,
            remotePath: remotePath,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
