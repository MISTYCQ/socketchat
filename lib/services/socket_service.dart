import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// Enhanced SocketService with private messaging support
/// 
/// Features:
/// - Private messaging to specific users
/// - User list management
/// - Message type differentiation (private/broadcast/system)
class EnhancedSocketService {
  Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _userListController = StreamController<List<String>>.broadcast();
  final StringBuffer _buffer = StringBuffer();
  
  String? _currentUsername;
  
  /// Stream of incoming messages (all types)
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  
  /// Stream of online users list
  Stream<List<String>> get userList => _userListController.stream;
  
  /// Check if socket is currently connected
  bool get isConnected => _socket != null;
  
  /// Current logged-in username
  String? get username => _currentUsername;

  /// Connect to the chat server
  Future<void> connect({
    required String host,
    required int port,
    required String username,
  }) async {
    try {
      _socket = await Socket.connect(host, port);
      _currentUsername = username;
      
      // Send username as handshake
      _socket!.write('$username\n');
      await _socket!.flush();

      // Listen for incoming data
      _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            _onData,
            onError: (e) {
              _messageController.addError(e);
              disconnect();
            },
            onDone: () {
              _messageController.add({
                "type": "system",
                "message": "Connection closed by server."
              });
              disconnect();
            },
            cancelOnError: false,
          );
    } catch (e) {
      _socket = null;
      _currentUsername = null;
      rethrow;
    }
  }

  /// Handle incoming data chunks from socket
  void _onData(String chunk) {
    _buffer.write(chunk);
    final data = _buffer.toString();
    final lines = data.split('\n');

    // Process all complete lines
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        _processMessage(line);
      }
    }

    // Keep incomplete last chunk in buffer
    _buffer.clear();
    _buffer.write(lines.last);
  }

  /// Process and categorize incoming messages
  void _processMessage(String raw) {
    try {
      // Try parsing as JSON first
      final data = json.decode(raw) as Map<String, dynamic>;
      
      if (data['type'] == 'user_list') {
        // User list update
        final users = List<String>.from(data['users'] ?? []);
        _userListController.add(users);
        return;
      }
      
      // Emit structured message
      _messageController.add(data);
      
    } catch (e) {
      // Not JSON, treat as legacy format
      if (raw.startsWith('[SERVER]')) {
        _messageController.add({
          'type': 'system',
          'message': raw.replaceFirst('[SERVER]', '').trim(),
        });
      } else {
        // Pattern: [username]: message
        final match = RegExp(r'^\[(.+?)\]: (.+)$').firstMatch(raw);
        if (match != null) {
          _messageController.add({
            'type': 'broadcast',
            'from': match.group(1),
            'message': match.group(2),
            'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
          });
        } else {
          _messageController.add({
            'type': 'system',
            'message': raw,
          });
        }
      }
    }
  }

  /// Send a private message to a specific user
  void sendPrivateMessage(String recipient, String message) {
    if (_socket != null && message.isNotEmpty) {
      try {
        final msg = json.encode({
          'type': 'private',
          'to': recipient,
          'message': message,
        });
        _socket!.write('$msg\n');
        _socket!.flush();
      } catch (e) {
        _messageController.addError(e);
        disconnect();
      }
    }
  }

  /// Send a broadcast message to all users
  void sendBroadcastMessage(String message) {
    if (_socket != null && message.isNotEmpty) {
      try {
        _socket!.write('$message\n');
        _socket!.flush();
      } catch (e) {
        _messageController.addError(e);
        disconnect();
      }
    }
  }

  /// Disconnect from the server
  void disconnect() {
    if (_socket != null) {
      try {
        _socket!.write('/quit\n');
        _socket!.flush();
      } catch (_) {}
      
      _socket?.destroy();
      _socket = null;
      _currentUsername = null;
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _userListController.close();
  }
}