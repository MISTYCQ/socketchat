import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = TextEditingController();
  final service = SocketService();

  void connect() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    await service.connect(
      host: "10.0.2.2",
      port: 12345,
      username: name,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          service: service,
          username: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: controller),
            ElevatedButton(
              onPressed: connect,
              child: const Text("Connect"),
            )
          ],
        ),
      ),
    );
  }
}