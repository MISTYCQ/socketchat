import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../theme.dart';

/// ChatScreen - Real-time chat interface
/// 
/// Features:
/// - Displays messages from all connected clients
/// - Listens to socket stream for incoming messages
/// - Sends messages through socket service
/// - Auto-scrolls to latest message
/// - Differentiates between user/system/incoming messages
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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _listenToMessages();
  }

  /// Subscribe to incoming messages from socket
  void _listenToMessages() {
    widget.service.messages.listen(
      (String rawMessage) {
        setState(() {
          _messages.add(ChatMessage.fromServer(rawMessage));
        });
        _scrollToBottom();
      },
      onError: (error) {
        _showError('Connection error: $error');
      },
    );
  }

  /// Send a message to the server
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add to local messages immediately for better UX
    setState(() {
      _messages.add(ChatMessage.own(text));
    });

    // Send to server
    widget.service.sendMessage(text);
    
    _controller.clear();
    _scrollToBottom();
  }

  /// Auto-scroll to bottom when new message arrives
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Show error snackbar
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Handle back button - disconnect from server
  Future<bool> _onWillPop() async {
    widget.service.disconnect();
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Socket Chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Connected as ${widget.username}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () {
              widget.service.disconnect();
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            // Connection status indicator
            if (!widget.service.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade900,
                child: const Text(
                  '⚠️ Disconnected from server',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),

            // Messages list
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: _messages[index]);
                      },
                    ),
            ),

            // Message input area
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  /// Empty state when no messages
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.systemText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.systemText.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.systemText.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Message input field with send button
  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: AppTheme.bg,
                onPressed: _sendMessage,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }
}