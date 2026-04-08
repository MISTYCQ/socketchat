import 'dart:async';
import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final SocketService service;
  final String username;

  const ChatScreen({
    super.key,
    required this.service,
    required this.username,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<String> messages = [];
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();

    sub = widget.service.messages.listen((raw) {
      print("🔥 UI GOT: $raw");

      setState(() {
        messages.add(raw); // ✅ NO parsing — DIRECT DISPLAY
      });
    });
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    widget.service.sendMessage(text);
    controller.clear();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                return ListTile(
                  title: Text(messages[i]), // ✅ RAW MESSAGE
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(controller: controller),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: send,
              )
            ],
          )
        ],
      ),
    );
  }
}