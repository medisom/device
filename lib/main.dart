import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:medisom_device/app/device_controller.dart';
import 'package:medisom_device/nav.dart';
import 'package:medisom_device/theme.dart';

/// Main entry point for the application
///
/// This sets up:
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DeviceController()..init())],
      child: MaterialApp.router(
        title: 'Medisom Device',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
