import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:medisom_device/features/home/home_page.dart';
import 'package:medisom_device/features/config/config_page.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:medisom_device/features/splash/splash_page.dart';

/// GoRouter configuration for app navigation
///
/// This uses go_router for declarative routing, which provides:
/// - Type-safe navigation
/// - Deep linking support (web URLs, app links)
/// - Easy route parameters
/// - Navigation guards and redirects
///
/// To add a new route:
/// 1. Add a route constant to AppRoutes below
/// 2. Add a GoRoute to the routes list
/// 3. Navigate using context.go() or context.push()
/// 4. Use context.pop() to go back.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
      ),
      GoRoute(
        path: AppRoutes.config,
        name: 'config',
        pageBuilder:
            (context, state) => MaterialPage(child: ConfigPage(device: state.extra! as DiscoveredDevice)),
      ),
    ],
  );
}

/// Route path constants
/// Use these instead of hard-coding route strings
class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String config = '/config';
}
