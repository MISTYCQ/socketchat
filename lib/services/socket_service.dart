import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// SocketService - Manages TCP socket connection to Python chat server
/// 
/// Features:
/// - Connects to TCP server with username handshake
/// - Streams incoming messages to listeners
/// - Sends messages to server
/// - Proper buffer handling for partial messages
/// - Error handling and connection lifecycle management
class SocketService {
  Socket? _socket;
  final _controller = StreamController<String>.broadcast();
  final StringBuffer _buffer = StringBuffer();
  
  /// Stream of incoming messages from the server
  Stream<String> get messages => _controller.stream;
  
  /// Check if socket is currently connected
  bool get isConnected => _socket != null;

  /// Connect to the chat server
  /// 
  /// [host] - Server IP address (e.g., '127.0.0.1' or '192.168.1.100')
  /// [port] - Server port (e.g., 12345)
  /// [username] - Username to send as handshake
  /// 
  /// Throws SocketException if connection fails
  Future<void> connect({
    required String host,
    required int port,
    required String username,
  }) async {
    try {
      // Connect to server
      _socket = await Socket.connect(host, port);
      
      // Send username as handshake (server expects this first)
      _socket!.write('$username\n');
      await _socket!.flush();

      // Listen for incoming data
      _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            _onData,
            onError: (e) {
              _controller.addError(e);
              disconnect();
            },
            onDone: () {
              _controller.add('[SERVER] Connection closed by server.');
              disconnect();
            },
            cancelOnError: false,
          );
    } catch (e) {
      _socket = null;
      rethrow;
    }
  }

  /// Handle incoming data chunks from socket
  /// 
  /// Buffers partial messages until newline is received
  void _onData(String chunk) {
    _buffer.write(chunk);
    final data = _buffer.toString();
    final lines = data.split('\n');

    // Process all complete lines (lines.length - 1 because last might be incomplete)
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        _controller.add(line);
      }
    }

    // Keep incomplete last chunk in buffer
    _buffer.clear();
    _buffer.write(lines.last);
  }

  /// Send a message to the server
  /// 
  /// Message will be sent with newline terminator
  void sendMessage(String message) {
    if (_socket != null && message.isNotEmpty) {
      try {
        _socket!.write('$message\n');
        _socket!.flush();
      } catch (e) {
        _controller.addError(e);
        disconnect();
      }
    }
  }

  /// Disconnect from the server
  /// 
  /// Sends /quit command and closes socket
  void disconnect() {
    if (_socket != null) {
      try {
        _socket!.write('/quit\n');
        _socket!.flush();
      } catch (_) {
        // Ignore errors during disconnect
      }
      
      _socket?.destroy();
      _socket = null;
    }
  }

  /// Dispose resources
  /// 
  /// Call this when the service is no longer needed
  void dispose() {
    disconnect();
    _controller.close();
  }
}