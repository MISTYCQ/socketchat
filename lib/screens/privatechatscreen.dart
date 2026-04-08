import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/enhanced_socket_service.dart';
import '../theme.dart';

/// PrivateChatScreen - One-on-one chat with a specific user
/// 
/// Features:
/// - Private messaging
/// - Message history for current session
/// - Typing indicator
/// - Delivery status
class PrivateChatScreen extends StatefulWidget {
  final EnhancedSocketService service;
  final String currentUsername;
  final String contactUsername;

  const PrivateChatScreen({
    super.key,
    required this.service,
    required this.currentUsername,
    required this.contactUsername,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _listenToMessages();
    _listenToUserList();
  }

  void _listenToMessages() {
    widget.service.messages.listen((data) {
      final type = data['type'] as String?;

      if (type == 'private') {
        // Incoming private message
        final from = data['from'] as String?;
        if (from == widget.contactUsername) {
          setState(() {
            _messages.add(ChatMessage(
              text: data['message'] as String,
              isOwn: false,
              timestamp: DateTime.now(),
              sender: from,
            ));
          });
          _scrollToBottom();
        }
      } else if (type == 'private_sent') {
        // Confirmation of sent message
        final to = data['to'] as String?;
        if (to == widget.contactUsername) {
          // Message already added optimistically
        }
      } else if (type == 'error') {
        _showError(data['message'] as String? ?? 'Unknown error');
      }
    });
  }

  void _listenToUserList() {
    widget.service.userList.listen((users) {
      setState(() {
        _isOnline = users.contains(widget.contactUsername);
      });
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add to UI immediately
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isOwn: true,
        timestamp: DateTime.now(),
        sender: widget.currentUsername,
      ));
    });

    // Send to server
    widget.service.sendPrivateMessage(widget.contactUsername, text);

    _controller.clear();
    _scrollToBottom();
  }

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.contactUsername.isNotEmpty
        ? widget.contactUsername[0].toUpperCase()
        : '?';
    final avatarColor = _getColorForUsername(widget.contactUsername);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor.withOpacity(0.2),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: avatarColor,
                    ),
                  ),
                ),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactUsername,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOnline ? Colors.green : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: _getColorForUsername(widget.contactUsername)
                .withOpacity(0.2),
            child: Text(
              widget.contactUsername[0].toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _getColorForUsername(widget.contactUsername),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chat with ${widget.contactUsername}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final time = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isOwn) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  _getColorForUsername(widget.contactUsername).withOpacity(0.2),
              child: Text(
                widget.contactUsername[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getColorForUsername(widget.contactUsername),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isOwn ? AppTheme.userBubble : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isOwn ? 16 : 4),
                  bottomRight: Radius.circular(message.isOwn ? 4 : 16),
                ),
                border: message.isOwn
                    ? Border.all(color: AppTheme.accentDim.withOpacity(0.3))
                    : Border.all(color: AppTheme.border),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.systemText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
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
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
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

  Color _getColorForUsername(String name) {
    const colors = [
      Color(0xFF00B89A),
      Color(0xFF5B8DD9),
      Color(0xFFD97B5B),
      Color(0xFF9B59B6),
      Color(0xFFE67E22),
      Color(0xFF3498DB),
      Color(0xFFE74C3C),
      Color(0xFF2ECC71),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}

class ChatMessage {
  final String text;
  final bool isOwn;
  final DateTime timestamp;
  final String sender;

  ChatMessage({
    required this.text,
    required this.isOwn,
    required this.timestamp,
    required this.sender,
  });
}