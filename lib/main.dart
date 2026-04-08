import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/enhanced_login_screen.dart';

void main() {
  runApp(const EnhancedChatApp());
}

class EnhancedChatApp extends StatelessWidget {
  const EnhancedChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Socket Chat',
      theme: AppTheme.theme,
      home: const EnhancedLoginScreen(),
    );
  }
}