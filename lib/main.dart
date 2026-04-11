import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() {
  runApp(const AutoZoneApp());
}

class AutoZoneApp extends StatelessWidget {
  const AutoZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..inicializar(),
      child: MaterialApp(
        title: 'AutoZone ITLA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _SplashRouter(),
      ),
    );
  }
}

// Decide a dónde ir al abrir la app
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Mientras verifica si hay sesión guardada
    if (!auth.inicializado) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

   
    return const DashboardScreen();
  }
}