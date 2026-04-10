import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const AutoZoneApp());
}

class AutoZoneApp extends StatelessWidget {
  const AutoZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoZone ITLA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text('AutoZone ITLA'),
        ),
      ),
    );
  }
}